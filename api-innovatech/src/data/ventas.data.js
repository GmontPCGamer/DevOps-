// Datos en memoria (simulan la BD MySQL del backend Spring Boot)
const ventas = [
  { id: 1, cliente: 'Empresa ABC',       producto: 'Laptop Pro',    cantidad: 2, precioUnit: 899990, fecha: '2024-01-15' },
  { id: 2, cliente: 'Comercial XYZ',     producto: 'Monitor 27"',   cantidad: 5, precioUnit: 249990, fecha: '2024-01-16' },
  { id: 3, cliente: 'Distribuidora Sur', producto: 'Teclado Mecánico', cantidad: 10, precioUnit: 59990, fecha: '2024-01-17' }
]

module.exports = ventas
