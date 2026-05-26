# Build da imagem Docker no Windows via Git Bash (evita o bash/WSL quebrado).
#
# Uso:
#   .\scripts\build-docker-windows.ps1
#   .\scripts\build-docker-windows.ps1 -Image "copapel/n8n" -Tag "1.0.0" -Push

param(
	[string]$Image = "copapel/n8n",
	[string]$Tag = "1.0.0",
	[switch]$Push
)

$ErrorActionPreference = "Stop"
$gitBash = "C:\Program Files\Git\bin\bash.exe"

if (-not (Test-Path $gitBash)) {
	Write-Error "Git Bash não encontrado em $gitBash. Instale: https://git-scm.com/download/win"
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function ConvertTo-GitBashPath {
	param([string]$WindowsPath)
	$resolved = (Resolve-Path $WindowsPath).Path
	if ($resolved -match '^([A-Za-z]):\\(.*)$') {
		$drive = $matches[1].ToLower()
		$rest = $matches[2] -replace '\\', '/'
		return "/$drive/$rest"
	}
	return ($resolved -replace '\\', '/')
}

$repoBash = ConvertTo-GitBashPath $repoRoot
$imageEsc = $Image -replace "'", "'\''"
$tagEsc = $Tag -replace "'", "'\''"

Write-Host "===== n8n Docker build (Windows / Git Bash) =====" -ForegroundColor Cyan
Write-Host "Imagem: ${Image}:${Tag}"
Write-Host "Repo:   $repoRoot"
Write-Host ""

# Roda todo o pipeline dentro do Git Bash para zx e comandos Unix (find, du, etc.)
$bashScript = @"
set -e
export SHELL='/bin/bash'
export IMAGE_BASE_NAME='$imageEsc'
export IMAGE_TAG='$tagEsc'
export N8N_DOCKER_SKIP_RUNNERS='true'
cd '$repoBash'
pnpm build:docker
"@

& $gitBash --login -c $bashScript
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Imagem local: ${Image}:${Tag}" -ForegroundColor Green
docker images "${Image}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

if ($Push) {
	Write-Host ""
	Write-Host "Enviando para Docker Hub..." -ForegroundColor Cyan
	docker push "${Image}:${Tag}"
	if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
	Write-Host "Push concluído: ${Image}:${Tag}" -ForegroundColor Green
} else {
	Write-Host ""
	Write-Host "Para enviar:" -ForegroundColor Yellow
	Write-Host "  docker login"
	Write-Host "  docker push `"${Image}:${Tag}`""
}
