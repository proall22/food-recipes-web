export default defineNuxtPlugin(() => {
  const { initAuth } = useAuth()
  
  // Initialize authentication state from localStorage
  initAuth()
})