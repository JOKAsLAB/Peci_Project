import { createApp } from 'vue'
import { createPinia } from 'pinia'
import router from './router' // Certifica-te de que este ficheiro existe
import './style.css'
import 'primeicons/primeicons.css' // Importação obrigatória para os ícones
import App from './App.vue'

const app = createApp(App)

app.use(createPinia())
app.use(router)

app.mount('#app')