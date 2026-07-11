import { execFile } from 'node:child_process'
import { copyFile, cp, mkdir, mkdtemp, rm, stat, writeFile } from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'
import process from 'node:process'
import { fileURLToPath } from 'node:url'
import { promisify } from 'node:util'

const execFileAsync = promisify(execFile)
const scriptDir = path.dirname(fileURLToPath(import.meta.url))
const rootDir = path.resolve(scriptDir, '../..')
const exampleDir = path.join(rootDir, 'example')
const solunaDir = path.join(rootDir, 'soluna')
const distDir = path.join(rootDir, 'dist')
const runtimeDir = path.join(distDir, 'runtime')

function resolveRuntimePath(name, fallback) {
  const value = process.env[name]
  return value ? path.resolve(rootDir, value) : fallback
}

async function ensureFile(filePath, label) {
  const exists = await stat(filePath).then(() => true, () => false)
  if (!exists) {
    throw new Error(`Missing ${label}: ${filePath}`)
  }
}

async function createZip(outputPath, cwd, entries) {
  await rm(outputPath, { force: true })
  await execFileAsync('zip', ['-qr', outputPath, ...entries], { cwd })
}

async function stageMainZip(outputPath) {
  const staging = await mkdtemp(path.join(os.tmpdir(), 'miru-main-'))
  try {
    await mkdir(path.join(staging, 'example'), { recursive: true })
    await copyFile(path.join(rootDir, 'miru.lua'), path.join(staging, 'miru.lua'))
    await copyFile(path.join(exampleDir, 'main.game'), path.join(staging, 'main.game'))
    for (const file of ['main.lua', 'gallery.lua', 'font.lua', 'palette.lua']) {
      await copyFile(path.join(exampleDir, file), path.join(staging, 'example', file))
    }
    await cp(path.join(exampleDir, 'components'), path.join(staging, 'example', 'components'), { recursive: true })
    await createZip(outputPath, staging, ['.'])
  }
  finally {
    await rm(staging, { recursive: true, force: true })
  }
}

async function stageFontZip(outputPath, fontPath) {
  const staging = await mkdtemp(path.join(os.tmpdir(), 'miru-font-'))
  try {
    const targetDir = path.join(staging, 'asset', 'font')
    await mkdir(targetDir, { recursive: true })
    await copyFile(fontPath, path.join(targetDir, 'SourceHanSansSC-Regular.ttf'))
    await createZip(outputPath, staging, ['asset'])
  }
  finally {
    await rm(staging, { recursive: true, force: true })
  }
}

async function main() {
  const mode = process.env.SOLUNA_MODE || 'release'
  const solunaJs = resolveRuntimePath('SOLUNA_JS_PATH', path.join(solunaDir, 'bin', 'emcc', mode, 'soluna.js'))
  const solunaWasm = resolveRuntimePath('SOLUNA_WASM_PATH', path.join(solunaDir, 'bin', 'emcc', mode, 'soluna.wasm'))
  const serviceWorker = path.join(solunaDir, 'website', 'public', 'coi-serviceworker.min.js')
  const fontPath = path.join(solunaDir, 'website', 'public', 'fonts', 'SourceHanSansSC-Regular.ttf')

  await Promise.all([
    ensureFile(solunaJs, 'soluna.js'),
    ensureFile(solunaWasm, 'soluna.wasm'),
    ensureFile(serviceWorker, 'COI service worker'),
    ensureFile(fontPath, 'example font'),
  ])

  await rm(distDir, { recursive: true, force: true })
  await mkdir(runtimeDir, { recursive: true })
  await cp(path.join(exampleDir, 'site'), distDir, { recursive: true })
  await copyFile(serviceWorker, path.join(distDir, 'coi-serviceworker.min.js'))
  await copyFile(solunaJs, path.join(runtimeDir, 'soluna.js'))
  await copyFile(solunaWasm, path.join(runtimeDir, 'soluna.wasm'))
  await createZip(path.join(runtimeDir, 'asset.zip'), solunaDir, ['asset'])
  await stageMainZip(path.join(runtimeDir, 'main.zip'))
  await stageFontZip(path.join(runtimeDir, 'font.zip'), fontPath)
  await writeFile(path.join(distDir, '.nojekyll'), '')

  process.stdout.write(`Built Miru documentation site in ${distDir}\n`)
}

main().catch((error) => {
  process.stderr.write(`${error instanceof Error ? error.message : String(error)}\n`)
  process.exitCode = 1
})
