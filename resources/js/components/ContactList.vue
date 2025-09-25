<template>
  <div class="contact-list">
    <div class="header">
      <h2>Imported Contacts</h2>
      <router-link to="/" class="btn btn-primary">
        Upload New CSV
      </router-link>
    </div>
    
    <div v-if="loading" class="loading">
      Loading contacts...
    </div>
    
    <div v-else-if="error" class="error-message">
      {{ error }}
    </div>
    
    <div v-else-if="contacts.length === 0" class="empty-state">
      <h3>No contacts found</h3>
      <p>Upload a CSV file to import contacts.</p>
      <router-link to="/" class="btn btn-primary">
        Upload CSV File
      </router-link>
    </div>
    
    <div v-else class="contacts-container">
      <div class="contacts-grid">
        <div 
          v-for="contact in contacts" 
          :key="contact.id" 
          class="contact-card"
        >
          <div class="contact-avatar">
            <img 
              :src="contact.gravatar_url" 
              :alt="contact.name"
              class="avatar-img"
            >
          </div>
          <div class="contact-info">
            <h3 class="contact-name">{{ contact.name }}</h3>
            <p class="contact-email">{{ contact.email }}</p>
            <p v-if="contact.phone" class="contact-phone">{{ contact.phone }}</p>
            <p v-if="contact.birthdate" class="contact-birthdate">
              Born: {{ formatDate(contact.birthdate) }}
            </p>
          </div>
        </div>
      </div>
      
      <div v-if="pagination.last_page > 1" class="pagination">
        <button 
          @click="goToPage(1)"
          :disabled="pagination.current_page === 1"
          class="pagination-btn"
        >
          First
        </button>
        
        <button 
          @click="goToPage(pagination.current_page - 1)"
          :disabled="pagination.current_page === 1"
          class="pagination-btn"
        >
          Previous
        </button>
        
        <span class="pagination-info">
          Page {{ pagination.current_page }} of {{ pagination.last_page }}
          ({{ pagination.total }} total contacts)
        </span>
        
        <button 
          @click="goToPage(pagination.current_page + 1)"
          :disabled="pagination.current_page === pagination.last_page"
          class="pagination-btn"
        >
          Next
        </button>
        
        <button 
          @click="goToPage(pagination.last_page)"
          :disabled="pagination.current_page === pagination.last_page"
          class="pagination-btn"
        >
          Last
        </button>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ContactList',
  data() {
    return {
      contacts: [],
      pagination: {},
      loading: false,
      error: null
    }
  },
  
  mounted() {
    this.loadContacts();
  },
  
  methods: {
    async loadContacts(page = 1) {
      this.loading = true;
      this.error = null;
      
      try {
        const response = await fetch(`/api/contacts?page=${page}`);
        
        if (!response.ok) {
          throw new Error('Failed to load contacts');
        }
        
        const data = await response.json();
        this.contacts = data.data;
        this.pagination = {
          current_page: data.current_page,
          last_page: data.last_page,
          total: data.total,
          per_page: data.per_page
        };
      } catch (err) {
        this.error = err.message || 'An error occurred while loading contacts';
      } finally {
        this.loading = false;
      }
    },
    
    goToPage(page) {
      if (page >= 1 && page <= this.pagination.last_page) {
        this.loadContacts(page);
      }
    },
    
    formatDate(dateString) {
      const date = new Date(dateString);
      return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      });
    }
  }
}
</script>

<style scoped>
.contact-list {
  max-width: 1200px;
  margin: 0 auto;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.loading {
  text-align: center;
  padding: 2rem;
  font-size: 1.2rem;
  color: #6c757d;
}

.error-message {
  background-color: #f8d7da;
  color: #721c24;
  padding: 1rem;
  border-radius: 0.25rem;
  margin: 1rem 0;
  text-align: center;
}

.empty-state {
  text-align: center;
  padding: 3rem;
  background: white;
  border-radius: 0.5rem;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.empty-state h3 {
  color: #6c757d;
  margin-bottom: 1rem;
}

.contacts-container {
  background: white;
  border-radius: 0.5rem;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  padding: 2rem;
}

.contacts-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.contact-card {
  border: 1px solid #dee2e6;
  border-radius: 0.5rem;
  padding: 1.5rem;
  transition: transform 0.2s, box-shadow 0.2s;
}

.contact-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.1);
}

.contact-avatar {
  text-align: center;
  margin-bottom: 1rem;
}

.avatar-img {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  border: 3px solid #dee2e6;
}

.contact-info {
  text-align: center;
}

.contact-name {
  font-size: 1.2rem;
  font-weight: bold;
  color: #333;
  margin-bottom: 0.5rem;
}

.contact-email {
  color: #007bff;
  font-weight: 500;
  margin-bottom: 0.5rem;
}

.contact-phone {
  color: #6c757d;
  margin-bottom: 0.5rem;
}

.contact-birthdate {
  color: #6c757d;
  font-size: 0.9rem;
}

.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 1rem;
  padding-top: 2rem;
  border-top: 1px solid #dee2e6;
}

.pagination-btn {
  background-color: #007bff;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 0.25rem;
  cursor: pointer;
  transition: background-color 0.2s;
}

.pagination-btn:hover:not(:disabled) {
  background-color: #0056b3;
}

.pagination-btn:disabled {
  background-color: #6c757d;
  cursor: not-allowed;
}

.pagination-info {
  color: #6c757d;
  font-weight: 500;
}

.btn {
  padding: 0.75rem 1.5rem;
  border-radius: 0.25rem;
  text-decoration: none;
  border: none;
  cursor: pointer;
  font-size: 1rem;
  transition: all 0.2s;
}

.btn-primary {
  background-color: #007bff;
  color: white;
}

.btn-primary:hover {
  background-color: #0056b3;
}
</style>

