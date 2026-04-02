#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');

// Firebase emülatörü başlatma ve testleri çalıştırma scripti
class EmulatorTestRunner {
  constructor() {
    this.emulatorProcess = null;
    this.testProcess = null;
    this.isCleaningUp = false;
  }

  async startEmulator() {
    return new Promise((resolve, reject) => {
      console.log('🚀 Firebase emülatörü başlatılıyor...');
      
      this.emulatorProcess = spawn('firebase', [
        'emulators:start',
        '--only', 'functions,firestore,auth,storage',
        '--project', 'stubstreet-test'
      ], {
        stdio: 'pipe',
        shell: true
      });

      let emulatorReady = false;
      
      this.emulatorProcess.stdout.on('data', (data) => {
        const output = data.toString();
        console.log(`📦 Emulator: ${output}`);
        
        // Emülatörün hazır olduğunu kontrol et
        if (output.includes('All emulators ready') || 
            output.includes('emulators started')) {
          emulatorReady = true;
          console.log('✅ Firebase emülatörü hazır!');
          resolve();
        }
      });

      this.emulatorProcess.stderr.on('data', (data) => {
        const error = data.toString();
        console.error(`❌ Emulator Error: ${error}`);
        if (!emulatorReady) {
          reject(new Error(`Emulator startup failed: ${error}`));
        }
      });

      this.emulatorProcess.on('close', (code) => {
        if (!emulatorReady && !this.isCleaningUp) {
          reject(new Error(`Emulator exited with code ${code}`));
        }
      });

      // Timeout after 30 seconds
      setTimeout(() => {
        if (!emulatorReady) {
          reject(new Error('Emulator startup timeout'));
        }
      }, 30000);
    });
  }

  async runTests() {
    return new Promise((resolve, reject) => {
      console.log('🧪 Jest testleri çalıştırılıyor...');
      
      this.testProcess = spawn('npm', ['test'], {
        stdio: 'inherit',
        shell: true,
        env: {
          ...process.env,
          NODE_ENV: 'test',
          FIRESTORE_EMULATOR_HOST: 'localhost:8080',
          FIREBASE_AUTH_EMULATOR_HOST: 'localhost:9099',
          FIREBASE_STORAGE_EMULATOR_HOST: 'localhost:9199',
        }
      });

      this.testProcess.on('close', (code) => {
        if (code === 0) {
          console.log('✅ Tüm testler başarılı!');
          resolve();
        } else {
          console.error(`❌ Testler başarısız! Exit code: ${code}`);
          reject(new Error(`Tests failed with exit code ${code}`));
        }
      });

      this.testProcess.on('error', (error) => {
        console.error(`❌ Test çalıştırma hatası: ${error.message}`);
        reject(error);
      });
    });
  }

  async cleanup() {
    this.isCleaningUp = true;
    console.log('🧹 Temizlik yapılıyor...');
    
    if (this.testProcess) {
      this.testProcess.kill('SIGTERM');
      this.testProcess = null;
    }

    if (this.emulatorProcess) {
      this.emulatorProcess.kill('SIGTERM');
      this.emulatorProcess = null;
    }

    // Emülatörün tamamen kapanması için kısa bir bekleme
    await new Promise(resolve => setTimeout(resolve, 2000));
    console.log('✅ Temizlik tamamlandı');
  }

  async run() {
    try {
      // Emülatörü başlat
      await this.startEmulator();
      
      // Emülatörün tam olarak hazır olması için kısa bir bekleme
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      // Testleri çalıştır
      await this.runTests();
      
      console.log('🎉 Tüm işlemler başarıyla tamamlandı!');
      
    } catch (error) {
      console.error(`💥 Hata: ${error.message}`);
      process.exit(1);
    } finally {
      await this.cleanup();
    }
  }
}

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🛑 Uygulama durduruluyor...');
  if (global.testRunner) {
    await global.testRunner.cleanup();
  }
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\n🛑 Uygulama sonlandırılıyor...');
  if (global.testRunner) {
    await global.testRunner.cleanup();
  }
  process.exit(0);
});

// Script çalıştırma
if (require.main === module) {
  const runner = new EmulatorTestRunner();
  global.testRunner = runner;
  runner.run();
}

module.exports = EmulatorTestRunner;
