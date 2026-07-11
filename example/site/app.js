const canvas = document.querySelector('#miru-canvas')
const status = document.querySelector('[data-runtime-status]')
const statusMessage = document.querySelector('[data-runtime-message]')

function setStatus(message) {
  statusMessage.textContent = message
  status.hidden = false
}

function hideStatus() {
  status.hidden = true
}

function runtimeUrl(path) {
  return new URL(path, document.baseURI).toString()
}

async function ensureCrossOriginIsolation() {
  if (window.crossOriginIsolated) {
    return true
  }
  if (!('serviceWorker' in navigator)) {
    throw new Error('This browser cannot establish cross-origin isolation.')
  }

  setStatus('Enabling cross-origin isolation...')
  await navigator.serviceWorker.register(runtimeUrl('coi-serviceworker.min.js'))
  if (!navigator.serviceWorker.controller) {
    window.location.reload()
    return false
  }
  return true
}

async function fetchBinary(path) {
  const response = await fetch(runtimeUrl(path))
  if (!response.ok) {
    throw new Error(`Failed to load ${path}: ${response.status}`)
  }
  return new Uint8Array(await response.arrayBuffer())
}

function ensureParentDirectory(runtime, path) {
  const index = path.lastIndexOf('/')
  if (index <= 0) {
    return
  }
  runtime.FS_createPath('/', path.slice(1, index), true, true)
}

function installFile(runtime, path, data) {
  ensureParentDirectory(runtime, path)
  runtime.FS.writeFile(path, data, { canOwn: true })
}

function resizeCanvas() {
  const rect = canvas.getBoundingClientRect()
  const ratio = Math.min(window.devicePixelRatio || 1, 2)
  const width = Math.max(1, Math.floor(rect.width * ratio))
  const height = Math.max(1, Math.floor(rect.height * ratio))
  if (canvas.width !== width || canvas.height !== height) {
    canvas.width = width
    canvas.height = height
  }
}

async function start() {
  if (!canvas || !status || !statusMessage) {
    return
  }
  if (!(await ensureCrossOriginIsolation())) {
    return
  }
  if (!navigator.gpu) {
    throw new Error('WebGPU is unavailable. Use a current Chrome, Edge, or Safari build.')
  }

  setStatus('Loading Miru example assets...')
  const [mainZip, assetZip, fontZip] = await Promise.all([
    fetchBinary('runtime/main.zip'),
    fetchBinary('runtime/asset.zip'),
    fetchBinary('runtime/font.zip'),
  ])

  setStatus('Starting Soluna WebAssembly...')
  resizeCanvas()
  const runtimeApi = await import(runtimeUrl('runtime/soluna.js'))
  if (typeof runtimeApi.default !== 'function') {
    throw new Error('soluna.js does not export a runtime factory.')
  }

  const resizeObserver = new ResizeObserver(resizeCanvas)
  resizeObserver.observe(canvas)
  canvas.addEventListener('pointerdown', () => canvas.focus())

  await runtimeApi.default({
    arguments: [
      'zipfile=/data/main.zip:/data/asset.zip:/data/font.zip',
      'cpath=/data/?.wasm',
    ],
    canvas,
    locateFile(path) {
      return runtimeUrl(`runtime/${path}`)
    },
    preRun: [
      (runtime) => {
        installFile(runtime, '/data/main.zip', mainZip)
        installFile(runtime, '/data/asset.zip', assetZip)
        installFile(runtime, '/data/font.zip', fontZip)
      },
    ],
    print(message) {
      console.info(`[soluna] ${message}`)
    },
    printErr(message) {
      console.error(`[soluna] ${message}`)
    },
    onAbort(reason) {
      resizeObserver.disconnect()
      setStatus(`Runtime aborted: ${String(reason || 'unknown error')}`)
    },
  })
  hideStatus()
}

start().catch((error) => {
  console.error(error)
  setStatus(error instanceof Error ? error.message : String(error))
})
