// SmartGovSpeech - Microphone & Audio Recording Helper
// Note: Web Speech API / SpeechRecognition disabled per requirement. Audio recording is handled via AudioRecorder / MediaRecorder & Whisper AI.

window.SmartGovSpeech = {
  isSupported: function() {
    return !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia);
  }
};
