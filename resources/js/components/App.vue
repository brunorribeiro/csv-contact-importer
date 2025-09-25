<template>
  <div id="app">
    <nav class="navbar">
      <div class="container">
        <h1 class="navbar-brand">CSV Contact Importer</h1>
        <div class="navbar-nav">
          <router-link to="/" class="nav-link">Upload</router-link>
          <router-link to="/contacts" class="nav-link">Contacts</router-link>
        </div>
      </div>
    </nav>
    
    <main class="container">
      <router-view></router-view>
    </main>
  </div>
</template>

<script>
export default {
  name: 'App'
}
</script>

<style scoped>
.navbar {
  background-color: #f8f9fa;
  padding: 1rem 0;
  border-bottom: 1px solid #dee2e6;
  margin-bottom: 2rem;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 1rem;
}

.navbar .container {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.navbar-brand {
  font-size: 1.5rem;
  font-weight: bold;
  color: #333;
  margin: 0;
}

.navbar-nav {
  display: flex;
  gap: 1rem;
}

.nav-link {
  text-decoration: none;
  color: #007bff;
  padding: 0.5rem 1rem;
  border-radius: 0.25rem;
  transition: background-color 0.2s;
}

.nav-link:hover {
  background-color: #e9ecef;
}

.nav-link.router-link-active {
  background-color: #007bff;
  color: white;
}
</style>

