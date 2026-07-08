# Contrato de Comunicación: Mobile -> Server (WebSocket)

**Payload Esperado (JSON)**
- `timestamp` (String, ISO 8601): Marca de tiempo del envío.
- `device_id` (String): Identificador único del móvil.
- `sensors` (Object):
  - `accelerometer`: [x, y, z] (Floats)
  - `gyroscope`: [x, y, z] (Floats)
- `frame` (String, Base64): Imagen comprimida en JPEG (320x240, calidad 50%).