const labels = [
  'Apple___Apple_scab', 'Apple___Black_rot', 'Apple___healthy',
  'Corn_(maize)___Common_rust', 'Corn_(maize)___Northern_Leaf_Blight', 'Corn_(maize)___healthy',
  'Grape___Black_rot', 'Grape___healthy',
  'Pepper_bell___Bacterial_spot', 'Pepper_bell___healthy',
  'Potato___Early_blight', 'Potato___Late_blight', 'Potato___healthy',
  'Tomato___Early_blight', 'Tomato___Late_blight',
  'Tomato___Tomato_Yellow_Leaf_Curl_Virus', 'Tomato___healthy',
];

const fungalClasses = new Set([
  'Apple___Apple_scab', 'Apple___Black_rot',
  'Corn_(maize)___Common_rust', 'Corn_(maize)___Northern_Leaf_Blight',
  'Grape___Black_rot', 'Potato___Early_blight', 'Potato___Late_blight',
  'Tomato___Early_blight', 'Tomato___Late_blight',
]);

const ui = {
  loginView: document.querySelector('#login-view'),
  detectorApp: document.querySelector('#detector-app'),
  loginForm: document.querySelector('#login-form'),
  loginEmail: document.querySelector('#login-email'),
  loginPassword: document.querySelector('#login-password'),
  loginError: document.querySelector('#login-error'),
  demoLogin: document.querySelector('#demo-login'),
  logout: document.querySelector('#logout-button'),
  modelStatus: document.querySelector('#model-status'),
  modelStatusText: document.querySelector('#model-status-text'),
  input: document.querySelector('#image-input'),
  dropzone: document.querySelector('#dropzone'),
  emptyState: document.querySelector('#empty-state'),
  preview: document.querySelector('#image-preview'),
  fileName: document.querySelector('#file-name'),
  analyze: document.querySelector('#analyze-button'),
  panel: document.querySelector('.result-panel'),
  state: document.querySelector('#result-state'),
  heading: document.querySelector('#result-heading'),
  copy: document.querySelector('#result-copy'),
  detail: document.querySelector('#result-detail'),
  className: document.querySelector('#class-name'),
  confidence: document.querySelector('#confidence'),
  error: document.querySelector('#error-message'),
};

let model;
let selectedFile;
let previewUrl;
const demoSessionKey = 'plantcare-demo-session';

function showDetector() {
  ui.loginView.hidden = true;
  ui.detectorApp.hidden = false;
  ui.modelStatus.hidden = false;
  ui.logout.hidden = false;
}

function signIn(email, password) {
  if (!email.trim() || !password) {
    ui.loginError.hidden = false;
    return;
  }
  sessionStorage.setItem(demoSessionKey, 'active');
  showDetector();
}

ui.loginForm.addEventListener('submit', (event) => {
  event.preventDefault();
  ui.loginError.hidden = true;
  signIn(ui.loginEmail.value, ui.loginPassword.value);
});

ui.demoLogin.addEventListener('click', () => {
  ui.loginEmail.value = 'demo@plantcare.ai';
  ui.loginPassword.value = 'demo123';
  ui.loginError.hidden = true;
  signIn(ui.loginEmail.value, ui.loginPassword.value);
});

ui.logout.addEventListener('click', () => {
  sessionStorage.removeItem(demoSessionKey);
  ui.detectorApp.hidden = true;
  ui.loginView.hidden = false;
  ui.modelStatus.hidden = true;
  ui.logout.hidden = true;
  ui.loginPassword.value = '';
});

if (sessionStorage.getItem(demoSessionKey) === 'active') showDetector();

function setResult(outcome, state, heading, copy, label, score) {
  ui.panel.dataset.outcome = outcome;
  ui.state.textContent = state;
  ui.heading.textContent = heading;
  ui.copy.textContent = copy;
  ui.detail.hidden = !label;
  ui.error.hidden = true;
  if (label) {
    ui.className.textContent = label.replaceAll('___', ' · ').replaceAll('_', ' ');
    ui.confidence.textContent = `${(score * 100).toFixed(1)}%`;
  }
}

function showError(message) {
  ui.panel.dataset.outcome = 'uncertain';
  ui.state.textContent = 'ERROR';
  ui.heading.textContent = 'Could not analyze image';
  ui.copy.textContent = 'The local model could not process this file.';
  ui.detail.hidden = true;
  ui.error.textContent = message;
  ui.error.hidden = false;
}

function selectFile(file) {
  if (!file) return;
  if (!file.type.startsWith('image/')) {
    showError('Choose an image file.');
    return;
  }
  if (previewUrl) URL.revokeObjectURL(previewUrl);
  selectedFile = file;
  previewUrl = URL.createObjectURL(file);
  ui.preview.src = previewUrl;
  ui.preview.hidden = false;
  ui.emptyState.hidden = true;
  ui.fileName.textContent = file.name;
  ui.analyze.disabled = !model;
  setResult('', 'READY', 'Ready to check', 'This image stays on your device and is not uploaded.');
  if (model) analyzeImage();
}

async function initializeModel() {
  try {
    await tf.setBackend('cpu');
    await tf.ready();
    tflite.setWasmPath(new URL('./vendor/', document.baseURI).href);
    model = await tflite.loadTFLiteModel(new URL('./plant_model.tflite', document.baseURI).href, { numThreads: 1 });
    ui.modelStatus.dataset.ready = 'true';
    ui.modelStatusText.textContent = 'Offline model ready';
    ui.analyze.disabled = !selectedFile;
    if (selectedFile) analyzeImage();
  } catch (error) {
    console.error(error);
    ui.modelStatus.dataset.error = 'true';
    ui.modelStatusText.textContent = 'Model unavailable';
    showError('The local classifier failed to load. Refresh the page and try again.');
  }
}

async function analyzeImage() {
  if (!selectedFile || !model) return;
  ui.analyze.disabled = true;
  ui.analyze.textContent = 'Analyzing…';
  setResult('', 'WORKING', 'Checking the leaf', 'Running the classifier locally on this device.');

  let pixels;
  let input;
  let output;
  let canvas;
  try {
    const bitmap = await createImageBitmap(selectedFile);
    canvas = document.createElement('canvas');
    canvas.width = 224;
    canvas.height = 224;
    canvas.getContext('2d', { willReadFrequently: true }).drawImage(bitmap, 0, 0, 224, 224);
    bitmap.close();
    pixels = tf.cast(tf.browser.fromPixels(canvas), 'float32');
    input = tf.expandDims(tf.div(pixels, 255), 0);
    output = model.predict(input);
    const scores = Array.from(output.dataSync());
    const bestIndex = scores.indexOf(Math.max(...scores));
    const label = labels[bestIndex];
    const score = scores[bestIndex];

    if (!label || score < 0.45) {
      setResult('uncertain', 'UNCERTAIN', 'No clear match', 'The image did not closely match a class this model knows. Try a closer, well-lit leaf photo.', label, score);
    } else if (fungalClasses.has(label)) {
      setResult('fungus', 'FUNGAL CLASS', 'Possible fungal infection detected', 'The model matched this leaf to a fungal disease class. Treat this as a screening result, not a confirmed diagnosis.', label, score);
    } else {
      setResult('clear', 'NO FUNGAL CLASS', 'No fungus detected', 'The model matched a healthy, bacterial, or viral class rather than a fungal class.', label, score);
    }
  } catch (error) {
    console.error(error);
    showError('Try a standard JPEG, PNG, or WebP image.');
  } finally {
    pixels?.dispose();
    input?.dispose();
    output?.dispose();
    if (canvas) canvas.width = canvas.height = 0;
    ui.analyze.disabled = !selectedFile || !model;
    ui.analyze.innerHTML = 'Analyze leaf <span aria-hidden="true">→</span>';
  }
}

ui.input.addEventListener('change', (event) => selectFile(event.target.files[0]));
ui.analyze.addEventListener('click', analyzeImage);
ui.dropzone.addEventListener('keydown', (event) => {
  if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault();
    ui.input.click();
  }
});
for (const eventName of ['dragenter', 'dragover']) {
  ui.dropzone.addEventListener(eventName, (event) => {
    event.preventDefault();
    ui.dropzone.classList.add('is-dragging');
  });
}
for (const eventName of ['dragleave', 'drop']) {
  ui.dropzone.addEventListener(eventName, (event) => {
    event.preventDefault();
    ui.dropzone.classList.remove('is-dragging');
  });
}
ui.dropzone.addEventListener('drop', (event) => selectFile(event.dataTransfer.files[0]));

initializeModel();