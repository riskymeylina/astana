# Pengujian QRIS Midtrans Sandbox

## Konfigurasi

Salin `backend/.env.example` menjadi `backend/.env`, lalu isi hanya di
server:

```env
MIDTRANS_SERVER_KEY=SB-Mid-server-...
MIDTRANS_CLIENT_KEY=SB-Mid-client-...
MIDTRANS_IS_PRODUCTION=false
```

Jangan masukkan Server Key atau Signature Key ke Flutter, Postman collection
yang dibagikan, Git, atau chat. Signature webhook Midtrans diverifikasi memakai
`MIDTRANS_SERVER_KEY`.

Restart backend setelah mengubah `.env`:

```bash
cd backend
npm run dev
```

## Pengujian melalui Postman

### Opsi A: uji langsung ke Midtrans

`POST https://api.sandbox.midtrans.com/v2/charge`

Headers:

```text
Authorization: Basic {{base64_server_key_colon}}
Content-Type: application/json
Accept: application/json
```

Nilai `base64_server_key_colon` adalah Base64 dari
`SB-Mid-server-...:` (Server Key diikuti titik dua). Jangan gunakan Client Key
untuk Basic Auth.

Body:

```json
{
  "payment_type": "qris",
  "transaction_details": {
    "order_id": "ASTANA-POSTMAN-001",
    "gross_amount": 10000
  },
  "customer_details": {
    "first_name": "Pembeli Sandbox",
    "phone": "081234567890"
  },
  "item_details": [
    {
      "id": "PROP-1",
      "price": 10000,
      "quantity": 1,
      "name": "Uji QRIS Astana Karya"
    }
  ],
  "qris": {
    "acquirer": "gopay"
  }
}
```

Respons sukses biasanya berisi `transaction_id`, `order_id`, `transaction_status`
`pending`, `expiry_time`, dan `actions` dengan action
`generate-qr-code`. Gunakan `actions[].url` sebagai gambar QRIS.

### Opsi B: uji melalui backend aplikasi

### 1. Login untuk mendapatkan token

`POST http://localhost:3000/api/auth/login`

Headers:

```text
Content-Type: application/json
```

Body:

```json
{
  "email": "email-pembeli-sandbox",
  "password": "password-pembeli-sandbox"
}
```

Salin `token` dari respons login. Endpoint pemesanan memakai token tersebut.

### 2. Buat pemesanan QRIS

`POST http://localhost:3000/api/purchases`

Headers:

```text
Content-Type: application/json
Authorization: Bearer {{buyer_token}}
```

Body:

```json
{
  "propertyId": 1,
  "paymentMethod": "QRIS",
  "buyerName": "Pembeli Sandbox",
  "buyerPhone": "081234567890",
  "buyerAddress": "Alamat pengujian",
  "notes": "Pengujian QRIS Midtrans Sandbox"
}
```

`propertyId` harus menunjuk properti yang masih tersedia. Respons sukses
mengandung:

```json
{
  "purchase": {
    "midtransOrderId": "ASTANA-...",
    "midtransTransactionId": "...",
    "midtransQrUrl": "https://...",
    "midtransPaymentStatus": "pending",
    "midtransExpiryTime": "..."
  }
}
```

`midtransQrUrl` adalah URL QR dinamis dari respons Midtrans dan dapat
ditampilkan menggunakan `Image.network` di aplikasi. Jika URL tidak ada,
backend mengembalikan error dan tidak membuat QR dummy.

### 3. Cek status

`GET http://localhost:3000/api/purchases/{{purchase_id}}/midtrans-status`

Headers:

```text
Authorization: Bearer {{buyer_token}}
```

Status yang diproses adalah `pending`, `settlement`, `expire`, dan `cancel`.
Status `settlement` mengubah pemesanan menjadi `confirmed`; `expire` atau
`cancel` mengubahnya menjadi `cancelled`.

## Webhook Midtrans

Atur URL notification pada Midtrans Sandbox ke:

```text
https://alamat-backend-yang-bisa-diakses-midtrans.com/api/purchases/midtrans-webhook
```

Untuk pengujian lokal, gunakan tunnel HTTPS seperti Cloudflare Tunnel atau
ngrok. Midtrans tidak dapat mengakses `localhost`.

Webhook tidak memerlukan login aplikasi. Backend memverifikasi
`signature_key`, menyimpan status Midtrans, memperbarui pemesanan, dan membuat
invoice idempotently setelah `settlement`.

## QRIS dan Payment Link

Keduanya adalah alur berbeda:

- **QRIS Core API**: backend memanggil `POST https://api.sandbox.midtrans.com/v2/charge`
  dengan `payment_type: "qris"`. Respons berisi QR dinamis untuk ditampilkan
  sendiri di aplikasi.
- **Payment Link**: Midtrans membuat URL halaman pembayaran yang di-host
  Midtrans. Pengguna membuka URL tersebut, lalu memilih metode pembayaran yang
  tersedia.

Keduanya dapat tersedia dalam satu sistem, tetapi satu pesanan sebaiknya
memakai satu alur pembayaran. Jangan membuat QRIS dan Payment Link untuk
order ID yang sama. Webhook tetap menjadi sumber pembaruan status untuk
keduanya.
