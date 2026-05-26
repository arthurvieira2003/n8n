/**
 * On Windows, zx otherwise picks WindowsApps\bash.exe (WSL stub) and fails.
 * Force Git Bash when available.
 */
import { $ } from 'zx';
import fs from 'fs';

const GIT_BASH_CANDIDATES = [
	'C:\\Program Files\\Git\\bin\\bash.exe',
	'C:\\Program Files (x86)\\Git\\bin\\bash.exe',
];

export function configureZxShellForWindows() {
	if (process.platform !== 'win32') {
		return;
	}

	for (const candidate of GIT_BASH_CANDIDATES) {
		if (fs.existsSync(candidate)) {
			$.shell = candidate;
			process.env.SHELL = candidate;
			return;
		}
	}

	console.warn(
		'[n8n] Git Bash não encontrado. Instale Git for Windows ou rode o build dentro do Git Bash.',
	);
}
