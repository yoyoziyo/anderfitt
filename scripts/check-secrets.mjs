import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';

const files = execFileSync('git', ['ls-files', '-z'], { encoding: 'utf8' }).split('\0').filter(Boolean);
const privatePath = /(^|\/)(\.release|\.dart_tool|build|node_modules)\/|(^|\/)\.env(?:\..+)?$|\.(jks|keystore|apk|aab|pem|p12|pfx)$|firebase-adminsdk|firebase-service-account|google-services\.json|key\.properties$/i;
const privateValue = /-----BEGIN (?:RSA |EC )?PRIVATE KEY-----|sbp_[a-f0-9]{40}|sb_secret_[A-Za-z0-9_-]{10,}/;
const bad = files.filter(path => privatePath.test(path) || privateValue.test(readFileSync(path, 'utf8')));
if (bad.length) throw new Error(`Arquivos privados no repositório: ${bad.join(', ')}`);
console.log(`${files.length} arquivos conferidos; nenhuma credencial privada encontrada.`);
