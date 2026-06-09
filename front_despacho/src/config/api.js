// En Kubernetes, Nginx hace el proxy internamente.
// El navegador siempre habla con el mismo origen (el Load Balancer),
// y Nginx redirige /api/ventas/ y /api/despachos/ al backend correcto.
const ventasApiUrl = "/api/ventas";
const despachosApiUrl = "/api/despachos";

export { ventasApiUrl, despachosApiUrl };