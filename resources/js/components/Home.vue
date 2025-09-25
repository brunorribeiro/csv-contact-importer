<template>
  <div class="home-container">
    <!-- Header Section -->
    <div class="header-section">
      <h1 class="main-title">CSV Contact Importer</h1>
      <p class="subtitle">Upload and process your contact files with real-time progress tracking</p>
    </div>

    <!-- Upload Section -->
    <div class="upload-card">
      <div class="upload-area" :class="{ 'drag-over': isDragOver, 'has-file': selectedFile }">
        <div class="upload-content">
          <div class="upload-icon">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M14 2H6C4.9 2 4 2.9 4 4V20C4 21.1 4.89 22 5.99 22H18C19.1 22 20 21.1 20 20V8L14 2Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              <polyline points="14,2 14,8 20,8" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              <line x1="16" y1="13" x2="8" y2="13" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              <line x1="16" y1="17" x2="8" y2="17" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              <polyline points="10,9 9,9 8,9" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </div>
          
          <div v-if="!selectedFile" class="upload-text">
            <h3>Browse file to upload</h3>
            <p>Drag and drop your CSV file here or click to browse</p>
            <p class="file-info">Supports CSV and TXT files up to 50MB</p>
          </div>
          
          <div v-else class="selected-file">
            <div class="file-icon">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M14 2H6C4.9 2 4 2.9 4 4V20C4 21.1 4.89 22 5.99 22H18C19.1 22 20 21.1 20 20V8L14 2Z" stroke="currentColor" stroke-width="2"/>
                <polyline points="14,2 14,8 20,8" stroke="currentColor" stroke-width="2"/>
              </svg>
            </div>
            <div class="file-details">
              <div class="file-name">{{ selectedFile.name }}</div>
              <div class="file-size">{{ formatFileSize(selectedFile.size) }}</div>
            </div>
            <button @click="removeFile" class="remove-btn" type="button">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <line x1="18" y1="6" x2="6" y2="18" stroke="currentColor" stroke-width="2"/>
                <line x1="6" y1="6" x2="18" y2="18" stroke="currentColor" stroke-width="2"/>
              </svg>
            </button>
          </div>
        </div>
        
        <input 
          type="file" 
          ref="fileInput"
          @change="handleFileSelect"
          @dragover.prevent="isDragOver = true"
          @dragleave.prevent="isDragOver = false"
          @drop.prevent="handleFileDrop"
          accept=".csv,.txt"
          class="file-input"
          :disabled="uploading"
        >
      </div>
      
      <div class="upload-actions">
        <button 
          @click="uploadFile" 
          class="upload-btn"
          :disabled="!selectedFile || uploading"
          :class="{ 'loading': uploading }"
        >
          <span v-if="!uploading">Upload and Process</span>
          <span v-else>Processing...</span>
        </button>
      </div>
    </div>

    <!-- Progress Section -->
    <div v-if="showProgress" class="progress-card">
      <div class="progress-header">
        <h3>Processing File</h3>
        <div class="progress-status" :class="progress.status">
          {{ progress.status }}
        </div>
      </div>
      
      <div class="file-info-row">
        <div class="file-icon-small">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M14 2H6C4.9 2 4 2.9 4 4V20C4 21.1 4.89 22 5.99 22H18C19.1 22 20 21.1 20 20V8L14 2Z" stroke="currentColor" stroke-width="2"/>
          </svg>
        </div>
        <div class="file-details-progress">
          <div class="file-name-progress">{{ progress.file_name || 'Processing...' }}</div>
          <div class="file-progress-text">{{ progress.message }}</div>
        </div>
        <div class="progress-percentage">{{ progress.percentage }}%</div>
      </div>
      
      <div class="progress-bar-container">
        <div class="progress-bar-track">
          <div 
            class="progress-bar-fill" 
            :style="{ width: progress.percentage + '%' }"
            :class="{ 'completed': progress.status === 'completed', 'failed': progress.status === 'failed' }"
          ></div>
        </div>
      </div>
      
      <div class="progress-stats">
        <div class="stat-item">
          <span class="stat-label">Rows:</span>
          <span class="stat-value">{{ progress.current_row || 0 }}/{{ progress.total_rows || 0 }}</span>
        </div>
        <div v-if="progress.imported !== undefined" class="stat-item">
          <span class="stat-label">Imported:</span>
          <span class="stat-value success">{{ progress.imported || 0 }}</span>
        </div>
        <div v-if="progress.duplicates !== undefined" class="stat-item">
          <span class="stat-label">Duplicates:</span>
          <span class="stat-value warning">{{ progress.duplicates || 0 }}</span>
        </div>
        <div v-if="progress.errors !== undefined" class="stat-item">
          <span class="stat-label">Errors:</span>
          <span class="stat-value error">{{ progress.errors || 0 }}</span>
        </div>
      </div>
    </div>

    <!-- Error Section -->
    <div v-if="error" class="error-card">
      <div class="error-icon">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/>
          <line x1="15" y1="9" x2="9" y2="15" stroke="currentColor" stroke-width="2"/>
          <line x1="9" y1="9" x2="15" y2="15" stroke="currentColor" stroke-width="2"/>
        </svg>
      </div>
      <div class="error-content">
        <h4>Upload Failed</h4>
        <p>{{ error }}</p>
      </div>
    </div>
    
    <!-- Results Section -->
    <div v-if="results" class="results-card">
      <div class="results-header">
        <div class="success-icon">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M22 11.08V12C21.9988 14.1564 21.3005 16.2547 20.0093 17.9818C18.7182 19.7088 16.9033 20.9725 14.8354 21.5839C12.7674 22.1953 10.5573 22.1219 8.53447 21.3746C6.51168 20.6273 4.78465 19.2461 3.61096 17.4371C2.43727 15.628 1.87979 13.4905 2.02168 11.3363C2.16356 9.18218 2.99721 7.13677 4.39828 5.49707C5.79935 3.85736 7.69279 2.71548 9.79619 2.24015C11.8996 1.76482 14.1003 1.98466 16.07 2.86" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            <polyline points="22,4 12,14.01 9,11.01" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </div>
        <div>
          <h3>Processing Complete</h3>
          <p>Your CSV file has been processed successfully</p>
        </div>
      </div>
      
      <div class="results-grid">
        <div class="result-card">
          <div class="result-number">{{ results.total_rows || 0 }}</div>
          <div class="result-label">Total Rows</div>
        </div>
        <div class="result-card success">
          <div class="result-number">{{ results.imported || 0 }}</div>
          <div class="result-label">Successfully Imported</div>
        </div>
        <div class="result-card warning">
          <div class="result-number">{{ results.duplicates || 0 }}</div>
          <div class="result-label">Duplicates Ignored</div>
        </div>
        <div class="result-card error">
          <div class="result-number">{{ results.validation_errors || 0 }}</div>
          <div class="result-label">Validation Errors</div>
        </div>
      </div>
      
      <div v-if="results.errors && results.errors.length > 0" class="errors-section">
        <h4>Error Details</h4>
        <div class="error-list">
          <div v-for="(error, index) in results.errors.slice(0, 5)" :key="index" class="error-item">
            {{ error }}
          </div>
          <div v-if="results.errors.length > 5" class="error-more">
            ... and {{ results.errors.length - 5 }} more errors
          </div>
        </div>
      </div>
      
      <div class="action-buttons">
        <router-link to="/contacts" class="btn btn-primary">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" stroke="currentColor" stroke-width="2"/>
            <circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="2"/>
          </svg>
          View Imported Contacts
        </router-link>
        <button @click="resetForm" class="btn btn-secondary">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <polyline points="1,4 1,10 7,10" stroke="currentColor" stroke-width="2"/>
            <path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10" stroke="currentColor" stroke-width="2"/>
          </svg>
          Upload Another File
        </button>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Home',
  data() {
    return {
      selectedFile: null,
      uploading: false,
      results: null,
      error: null,
      isDragOver: false,
      showProgress: false,
      progress: {
        percentage: 0,
        current_row: 0,
        total_rows: 0,
        status: 'waiting',
        message: 'Waiting...',
        file_name: '',
        imported: 0,
        duplicates: 0,
        errors: 0
      },
      sessionId: null,
      progressInterval: null
    }
  },
  beforeUnmount() {
    this.stopProgressMonitoring();
  },
  methods: {
    handleFileSelect(event) {
      const file = event.target.files[0];
      if (file) {
        this.selectedFile = file;
        this.error = null;
      }
    },
    
    handleFileDrop(event) {
      this.isDragOver = false;
      const files = event.dataTransfer.files;
      if (files.length > 0) {
        const file = files[0];
        if (file.type === 'text/csv' || file.name.endsWith('.csv') || file.name.endsWith('.txt')) {
          this.selectedFile = file;
          this.error = null;
        } else {
          this.error = 'Please select a CSV or TXT file';
        }
      }
    },
    
    removeFile() {
      this.selectedFile = null;
      this.$refs.fileInput.value = '';
    },
    
    async uploadFile() {
      if (!this.selectedFile) return;
      
      this.uploading = true;
      this.error = null;
      this.results = null;
      this.showProgress = true;
      this.sessionId = 'upload_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
      
      // Reset progress
      this.progress = {
        percentage: 0,
        current_row: 0,
        total_rows: 0,
        status: 'uploading',
        message: 'Uploading file...',
        file_name: this.selectedFile.name,
        imported: 0,
        duplicates: 0,
        errors: 0
      };
      
      const formData = new FormData();
      formData.append('csv_file', this.selectedFile);
      formData.append('session_id', this.sessionId);
      
      try {
        const response = await fetch('/api/contacts/upload', {
          method: 'POST',
          body: formData,
          headers: {
            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
          }
        });
        
        const data = await response.json();
        
        if (!response.ok) {
          throw new Error(data.error || 'Upload failed');
        }
        
        // Start progress monitoring after successful upload
        this.startProgressMonitoring();
        
      } catch (err) {
        this.error = err.message || 'An error occurred during upload';
        this.showProgress = false;
        this.uploading = false;
      }
    },
    
    startProgressMonitoring() {
      this.progressInterval = setInterval(async () => {
        if (!this.sessionId) return;
        
        try {
          const response = await fetch(`/api/upload/progress?session_id=${this.sessionId}`);
          if (response.ok) {
            const progressData = await response.json();
            this.progress = { ...this.progress, ...progressData };
            
            // Stop monitoring when completed or failed
            if (progressData.status === 'completed') {
              this.stopProgressMonitoring();
              this.uploading = false;
              if (progressData.results) {
                this.results = progressData.results;
              }
            } else if (progressData.status === 'failed') {
              this.stopProgressMonitoring();
              this.uploading = false;
              this.error = progressData.error || 'Processing failed';
              this.showProgress = false;
            }
          }
        } catch (err) {
          console.error('Error fetching progress:', err);
        }
      }, 250); // Check every 250ms for more responsive updates
    },
    
    stopProgressMonitoring() {
      if (this.progressInterval) {
        clearInterval(this.progressInterval);
        this.progressInterval = null;
      }
    },
    
    resetForm() {
      this.selectedFile = null;
      this.results = null;
      this.error = null;
      this.sessionId = null;
      this.showProgress = false;
      this.uploading = false;
      this.stopProgressMonitoring();
      this.progress = {
        percentage: 0,
        current_row: 0,
        total_rows: 0,
        status: 'waiting',
        message: 'Waiting...',
        file_name: '',
        imported: 0,
        duplicates: 0,
        errors: 0
      };
      this.$refs.fileInput.value = '';
    },
    
    formatFileSize(bytes) {
      if (bytes === 0) return '0 Bytes';
      const k = 1024;
      const sizes = ['Bytes', 'KB', 'MB', 'GB'];
      const i = Math.floor(Math.log(bytes) / Math.log(k));
      return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }
  }
}
</script>

<style scoped>
.home-container {
  max-width: 800px;
  margin: 0 auto;
  padding: 2rem 1rem;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

/* Header Section */
.header-section {
  text-align: center;
  margin-bottom: 3rem;
}

.main-title {
  font-size: 2.5rem;
  font-weight: 700;
  color: #1a1a1a;
  margin-bottom: 0.5rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.subtitle {
  font-size: 1.1rem;
  color: #666;
  margin: 0;
}

/* Upload Card */
.upload-card {
  background: white;
  border-radius: 16px;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
  padding: 2rem;
  margin-bottom: 2rem;
  border: 1px solid #e5e7eb;
}

.upload-area {
  position: relative;
  border: 2px dashed #d1d5db;
  border-radius: 12px;
  padding: 3rem 2rem;
  text-align: center;
  transition: all 0.3s ease;
  background: #fafafa;
  cursor: pointer;
}

.upload-area:hover {
  border-color: #667eea;
  background: #f8faff;
}

.upload-area.drag-over {
  border-color: #667eea;
  background: #f0f4ff;
  transform: scale(1.02);
}

.upload-area.has-file {
  border-color: #10b981;
  background: #f0fdf4;
}

.file-input {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  opacity: 0;
  cursor: pointer;
}

.upload-content {
  pointer-events: none;
}

.upload-icon {
  color: #9ca3af;
  margin-bottom: 1rem;
  transition: color 0.3s ease;
}

.upload-area:hover .upload-icon {
  color: #667eea;
}

.upload-text h3 {
  font-size: 1.25rem;
  font-weight: 600;
  color: #374151;
  margin-bottom: 0.5rem;
}

.upload-text p {
  color: #6b7280;
  margin-bottom: 0.25rem;
}

.file-info {
  font-size: 0.875rem;
  color: #9ca3af;
}

.selected-file {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  background: white;
  border-radius: 8px;
  border: 1px solid #e5e7eb;
}

.file-icon {
  color: #10b981;
}

.file-details {
  flex: 1;
  text-align: left;
}

.file-name {
  font-weight: 600;
  color: #374151;
  margin-bottom: 0.25rem;
}

.file-size {
  font-size: 0.875rem;
  color: #6b7280;
}

.remove-btn {
  background: none;
  border: none;
  color: #ef4444;
  cursor: pointer;
  padding: 0.5rem;
  border-radius: 4px;
  transition: background-color 0.2s;
}

.remove-btn:hover {
  background: #fef2f2;
}

.upload-actions {
  margin-top: 1.5rem;
  text-align: center;
}

.upload-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  padding: 0.875rem 2rem;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 4px 14px 0 rgba(102, 126, 234, 0.39);
}

.upload-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px 0 rgba(102, 126, 234, 0.5);
}

.upload-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

.upload-btn.loading {
  position: relative;
}

/* Progress Card */
.progress-card {
  background: white;
  border-radius: 16px;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  padding: 2rem;
  margin-bottom: 2rem;
  border: 1px solid #e5e7eb;
}

.progress-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.progress-header h3 {
  font-size: 1.25rem;
  font-weight: 600;
  color: #374151;
  margin: 0;
}

.progress-status {
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.875rem;
  font-weight: 500;
  text-transform: capitalize;
}

.progress-status.queued {
  background: #fef3c7;
  color: #92400e;
}

.progress-status.processing {
  background: #dbeafe;
  color: #1e40af;
}

.progress-status.completed {
  background: #d1fae5;
  color: #065f46;
}

.progress-status.failed {
  background: #fee2e2;
  color: #991b1b;
}

.file-info-row {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1rem;
}

.file-icon-small {
  color: #6b7280;
}

.file-details-progress {
  flex: 1;
}

.file-name-progress {
  font-weight: 600;
  color: #374151;
  margin-bottom: 0.25rem;
}

.file-progress-text {
  font-size: 0.875rem;
  color: #6b7280;
}

.progress-percentage {
  font-weight: 700;
  font-size: 1.125rem;
  color: #667eea;
}

.progress-bar-container {
  margin-bottom: 1.5rem;
}

.progress-bar-track {
  width: 100%;
  height: 8px;
  background: #f3f4f6;
  border-radius: 4px;
  overflow: hidden;
}

.progress-bar-fill {
  height: 100%;
  background: linear-gradient(90deg, #667eea, #764ba2);
  border-radius: 4px;
  transition: width 0.3s ease;
  position: relative;
}

.progress-bar-fill::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  bottom: 0;
  right: 0;
  background-image: linear-gradient(
    -45deg,
    rgba(255, 255, 255, 0.2) 25%,
    transparent 25%,
    transparent 50%,
    rgba(255, 255, 255, 0.2) 50%,
    rgba(255, 255, 255, 0.2) 75%,
    transparent 75%,
    transparent
  );
  background-size: 30px 30px;
  animation: move 2s linear infinite;
}

.progress-bar-fill.completed {
  background: linear-gradient(90deg, #10b981, #059669);
}

.progress-bar-fill.failed {
  background: linear-gradient(90deg, #ef4444, #dc2626);
}

@keyframes move {
  0% {
    background-position: 0 0;
  }
  100% {
    background-position: 30px 30px;
  }
}

.progress-stats {
  display: flex;
  gap: 2rem;
  flex-wrap: wrap;
}

.stat-item {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

.stat-label {
  font-size: 0.875rem;
  color: #6b7280;
}

.stat-value {
  font-weight: 600;
  color: #374151;
}

.stat-value.success {
  color: #10b981;
}

.stat-value.warning {
  color: #f59e0b;
}

.stat-value.error {
  color: #ef4444;
}

/* Error Card */
.error-card {
  background: #fef2f2;
  border: 1px solid #fecaca;
  border-radius: 12px;
  padding: 1.5rem;
  margin-bottom: 2rem;
  display: flex;
  gap: 1rem;
  align-items: flex-start;
}

.error-icon {
  color: #ef4444;
  flex-shrink: 0;
}

.error-content h4 {
  color: #991b1b;
  font-weight: 600;
  margin: 0 0 0.5rem 0;
}

.error-content p {
  color: #7f1d1d;
  margin: 0;
}

/* Results Card */
.results-card {
  background: white;
  border-radius: 16px;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  padding: 2rem;
  border: 1px solid #e5e7eb;
}

.results-header {
  display: flex;
  gap: 1rem;
  align-items: flex-start;
  margin-bottom: 2rem;
}

.success-icon {
  color: #10b981;
  flex-shrink: 0;
}

.results-header h3 {
  font-size: 1.25rem;
  font-weight: 600;
  color: #374151;
  margin: 0 0 0.25rem 0;
}

.results-header p {
  color: #6b7280;
  margin: 0;
}

.results-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
}

.result-card {
  background: #f9fafb;
  padding: 1.5rem;
  border-radius: 12px;
  text-align: center;
  border-left: 4px solid #e5e7eb;
  transition: transform 0.2s ease;
}

.result-card:hover {
  transform: translateY(-2px);
}

.result-card.success {
  border-left-color: #10b981;
  background: #f0fdf4;
}

.result-card.warning {
  border-left-color: #f59e0b;
  background: #fffbeb;
}

.result-card.error {
  border-left-color: #ef4444;
  background: #fef2f2;
}

.result-number {
  font-size: 2rem;
  font-weight: 700;
  color: #374151;
  margin-bottom: 0.5rem;
}

.result-label {
  color: #6b7280;
  font-size: 0.875rem;
  font-weight: 500;
}

.errors-section {
  margin-bottom: 2rem;
}

.errors-section h4 {
  color: #374151;
  font-weight: 600;
  margin-bottom: 1rem;
}

.error-list {
  background: #f9fafb;
  border-radius: 8px;
  padding: 1rem;
  max-height: 200px;
  overflow-y: auto;
}

.error-item {
  padding: 0.5rem 0;
  border-bottom: 1px solid #e5e7eb;
  color: #7f1d1d;
  font-size: 0.875rem;
}

.error-item:last-child {
  border-bottom: none;
}

.error-more {
  padding: 0.5rem 0;
  color: #6b7280;
  font-style: italic;
  font-size: 0.875rem;
}

.action-buttons {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

.btn {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  text-decoration: none;
  border: none;
  cursor: pointer;
  font-size: 0.875rem;
  font-weight: 600;
  transition: all 0.2s ease;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  box-shadow: 0 4px 14px 0 rgba(102, 126, 234, 0.39);
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px 0 rgba(102, 126, 234, 0.5);
}

.btn-secondary {
  background: #f9fafb;
  color: #374151;
  border: 1px solid #d1d5db;
}

.btn-secondary:hover {
  background: #f3f4f6;
  transform: translateY(-1px);
}

/* Responsive Design */
@media (max-width: 768px) {
  .home-container {
    padding: 1rem;
  }
  
  .main-title {
    font-size: 2rem;
  }
  
  .upload-card,
  .progress-card,
  .results-card {
    padding: 1.5rem;
  }
  
  .upload-area {
    padding: 2rem 1rem;
  }
  
  .results-grid {
    grid-template-columns: 1fr;
  }
  
  .action-buttons {
    flex-direction: column;
  }
  
  .progress-stats {
    gap: 1rem;
  }
  
  .file-info-row {
    flex-wrap: wrap;
  }
  
  .progress-percentage {
    order: -1;
    width: 100%;
    text-align: right;
  }
}
</style>
