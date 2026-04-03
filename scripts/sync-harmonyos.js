import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const rootDir = path.resolve(__dirname, '..');
const distDir = path.join(rootDir, 'dist');
const rawfileDir = path.join(rootDir, 'harmonyos', 'entry', 'src', 'main', 'resources', 'rawfile');

function copyDirectory(src, dest) {
  if (!fs.existsSync(dest)) {
    fs.mkdirSync(dest, { recursive: true });
  }
  
  const entries = fs.readdirSync(src, { withFileTypes: true });
  
  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    
    if (entry.isDirectory()) {
      copyDirectory(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

function main() {
  console.log('🚀 开始同步 Web 资源到 HarmonyOS...\n');
  
  if (!fs.existsSync(distDir)) {
    console.error('❌ dist 目录不存在，请先运行 pnpm build');
    process.exit(1);
  }
  
  if (fs.existsSync(rawfileDir)) {
    fs.rmSync(rawfileDir, { recursive: true });
  }
  fs.mkdirSync(rawfileDir, { recursive: true });
  
  copyDirectory(distDir, rawfileDir);
  
  console.log('✅ Web 资源已同步到 harmonyos/entry/src/main/resources/rawfile');
  console.log('\n下一步：');
  console.log('  1. 使用 DevEco Studio 打开 harmonyos 目录');
  console.log('  2. 配置签名（Build → Generate Key and CSR）');
  console.log('  3. 构建 HAP（Build → Build Hap(s)/APP(s) → Build Hap(s)');
}

main();
