import { readdirSync, statSync, existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const root = 'src/build/web';
function walk(dir) {
  return readdirSync(dir).flatMap(name => {
    const path = join(dir, name);
    return statSync(path).isDirectory() ? walk(path) : [path];
  });
}
const required = ['index.html', 'main.dart.js', 'flutter_bootstrap.js', 'manifest.json', 'pdf-loader.mjs', 'vendor/pdfjs/pdf.min.mjs', 'vendor/pdfjs/pdf.worker.min.mjs'];
for (const path of required) if (!existsSync(join(root, path))) throw new Error(`Arquivo web ausente: ${path}`);
const files = walk(root);
for (const path of files) {
  if (statSync(path).size > 25 * 1024 * 1024) throw new Error(`Arquivo excede o limite da Cloudflare: ${path}`);
  if (/\.release|firebase-adminsdk|firebase-service-account|google-services\.json|(^|[\\/])(backend|supabase|test|scripts)[\\/]|\.(jks|keystore|pem|p12|pfx|map)$/.test(path)) throw new Error(`Arquivo privado ou de desenvolvimento no pacote: ${path}`);
}
const pdfs = files.filter(path => path.toLowerCase().endsWith('.pdf'));
if (pdfs.length !== 59) throw new Error(`Esperados 59 PDFs; encontrados ${pdfs.length}`);
if (readFileSync(join(root, 'index.html'), 'utf8').includes('$FLUTTER_BASE_HREF')) throw new Error('Base URL do site não foi resolvida.');
const expectedBase = process.argv[2] ?? '/';
if (!readFileSync(join(root, 'index.html'), 'utf8').includes(`<base href="${expectedBase}">`)) throw new Error(`Base URL incorreta; esperado ${expectedBase}`);
console.log(`Pacote web pronto: ${files.length} arquivos, ${pdfs.length} PDFs; todos abaixo de 25 MiB.`);
