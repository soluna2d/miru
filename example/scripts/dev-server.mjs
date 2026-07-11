import { createReadStream } from 'node:fs'
import { stat } from 'node:fs/promises'
import http from 'node:http'
import path from 'node:path'
import process from 'node:process'
import { fileURLToPath } from 'node:url'

const scriptDir = path.dirname(fileURLToPath(import.meta.url))
const rootDir = path.resolve(scriptDir, '../..')
const distDir = path.join(rootDir, 'dist')
const port = Number.parseInt(process.env.PORT || process.argv[2] || '4173', 10)

const MIME_TYPES = new Map([
  ['.css', 'text/css; charset=utf-8'],
  ['.html', 'text/html; charset=utf-8'],
  ['.js', 'text/javascript; charset=utf-8'],
  ['.json', 'application/json; charset=utf-8'],
  ['.wasm', 'application/wasm'],
  ['.zip', 'application/zip'],
])

function sendError(response, statusCode, message) {
  response.writeHead(statusCode, { 'Content-Type': 'text/plain; charset=utf-8' })
  response.end(message)
}

function resolveRequestPath(url) {
  const requestPath = decodeURIComponent(new URL(url, 'http://localhost').pathname)
  const relativePath = requestPath === '/' ? 'index.html' : requestPath.slice(1)
  const filePath = path.resolve(distDir, relativePath)
  if (filePath !== distDir && !filePath.startsWith(`${distDir}${path.sep}`)) {
    return undefined
  }
  return filePath
}

const server = http.createServer(async (request, response) => {
  response.setHeader('Cross-Origin-Embedder-Policy', 'require-corp')
  response.setHeader('Cross-Origin-Opener-Policy', 'same-origin')
  response.setHeader('Cache-Control', 'no-store')

  const filePath = resolveRequestPath(request.url || '/')
  if (!filePath) {
    sendError(response, 400, 'Invalid path')
    return
  }

  const fileStat = await stat(filePath).catch(() => undefined)
  if (!fileStat?.isFile()) {
    sendError(response, 404, 'Not found')
    return
  }

  response.writeHead(200, {
    'Content-Type': MIME_TYPES.get(path.extname(filePath)) || 'application/octet-stream',
  })
  createReadStream(filePath).pipe(response)
})

server.listen(port, '127.0.0.1', () => {
  process.stdout.write(`Miru docs available at http://127.0.0.1:${port}\n`)
})
