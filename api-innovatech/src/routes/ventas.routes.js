const express  = require('express')
const router   = express.Router()
const ventas   = require('../data/ventas.data')

// GET /api/v1/ventas  → listar todas
router.get('/', (_req, res) => {
  res.json({ total: ventas.length, data: ventas })
})

// GET /api/v1/ventas/:id  → buscar por id
router.get('/:id', (req, res) => {
  const venta = ventas.find(v => v.id === Number(req.params.id))
  if (!venta) return res.status(404).json({ error: 'Venta no encontrada' })
  res.json(venta)
})

// POST /api/v1/ventas  → crear nueva venta
router.post('/', (req, res) => {
  const { cliente, producto, cantidad, precioUnit } = req.body

  if (!cliente || !producto || !cantidad || !precioUnit) {
    return res.status(400).json({ error: 'Campos requeridos: cliente, producto, cantidad, precioUnit' })
  }

  const nuevaVenta = {
    id       : ventas.length + 1,
    cliente,
    producto,
    cantidad : Number(cantidad),
    precioUnit: Number(precioUnit),
    fecha    : new Date().toISOString().split('T')[0]
  }

  ventas.push(nuevaVenta)
  res.status(201).json(nuevaVenta)
})

// DELETE /api/v1/ventas/:id  → eliminar venta
router.delete('/:id', (req, res) => {
  const idx = ventas.findIndex(v => v.id === Number(req.params.id))
  if (idx === -1) return res.status(404).json({ error: 'Venta no encontrada' })

  const eliminada = ventas.splice(idx, 1)[0]
  res.json({ mensaje: 'Venta eliminada', data: eliminada })
})

module.exports = router
