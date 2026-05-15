// Datos en memoria (simulan la BD MySQL del backend Spring Boot)
const despachos = [
  { id: 1, ventaId: 1, estado: 'entregado',  direccion: 'Av. Providencia 123, Santiago', transportista: 'Chilexpress', fechaEnvio: '2024-01-16', fechaEntrega: '2024-01-18' },
  { id: 2, ventaId: 2, estado: 'en_tránsito', direccion: 'Calle Larga 456, Valparaíso',   transportista: 'Starken',    fechaEnvio: '2024-01-17', fechaEntrega: null },
  { id: 3, ventaId: 3, estado: 'pendiente',   direccion: 'Baquedano 789, Concepción',     transportista: null,         fechaEnvio: null,         fechaEntrega: null }
]

module.exports = despachos
