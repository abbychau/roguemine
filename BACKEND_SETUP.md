# RogueMine Backend Setup Guide

This guide will help you set up the RogueMine highscore backend with custom encoding/decoding for secure score storage.

## Overview

The backend system includes:
- **Node.js Express Server**: RESTful API for highscore management
- **Custom Encoding Algorithm**: Multi-layered security to prevent data forgery
- **SQLite Database**: Lightweight storage with proper indexing
- **Rate Limiting**: Prevents spam and abuse
- **Input Validation**: Server-side validation and suspicious pattern detection
- **GDScript Integration**: Client libraries for Godot integration

## Quick Start

### Windows
1. Open Command Prompt or PowerShell
2. Navigate to the backend directory:
   ```cmd
   cd backend
   ```
3. Run the startup script:
   ```cmd
   start-server.bat
   ```

### Linux/macOS
1. Open Terminal
2. Navigate to the backend directory:
   ```bash
   cd backend
   ```
3. Make the script executable and run:
   ```bash
   chmod +x start-server.sh
   ./start-server.sh
   ```

## Manual Setup

### Prerequisites
- **Node.js** (version 16 or higher) - Download from [nodejs.org](https://nodejs.org/)
- **npm** (comes with Node.js)

### Installation Steps

1. **Install Dependencies**
   ```bash
   cd backend
   npm install
   ```

2. **Configure Environment**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` file with your settings:
   ```env
   PORT=56789
   ENCODING_SECRET=your-secret-key-here-change-this-in-production
   ALLOWED_ORIGINS=http://localhost:8080,http://127.0.0.1:8080,https://mine-api.12389012.xyz
   ```

3. **Start the Server**
   ```bash
   npm start
   ```
   
   For development with auto-reload:
   ```bash
   npm run dev
   ```

4. **Verify Installation**
   Open your browser and visit: http://localhost:56789/health
   
   You should see:
   ```json
   {
     "status": "OK",
     "timestamp": "2024-01-01T12:00:00.000Z",
     "version": "1.0.0"
   }
   ```

## Godot Integration

### 1. Copy GDScript Files
Copy these files to your Godot project's `scripts/` directory:
- `scripts/RogueMineEncoder.gd`
- `scripts/RogueMineAPIClient.gd`

### 2. Update HighscoreManager
The `HighscoreManager.gd` has been updated to support online functionality. Key changes:
- Added backend communication
- Automatic encoding of score data
- Online/offline synchronization
- Error handling and retry logic

### 3. Configure Backend URL
In `HighscoreManager.gd`, the backend URL is configured to use the tunnel:
```gdscript
const BACKEND_URL = "https://mine-api.12389012.xyz"
const ENCODING_SECRET = "your-secret-key-here"
```

### 4. Test Integration
In your game, the highscore submission will now automatically:
1. Save scores locally (existing functionality)
2. Encode the score data using the custom algorithm
3. Submit to the backend server
4. Handle online/offline scenarios gracefully

## Security Features

### Custom Encoding Algorithm
The system uses a multi-layered approach:

1. **Data Validation**: Input sanitization and range checking
2. **Timestamp Verification**: Prevents replay attacks (5-minute window)
3. **Checksum Calculation**: Detects data tampering using secret key
4. **XOR Cipher**: Obfuscates data with rotating key based on timestamp
5. **Base64 Encoding**: Safe transport encoding

### Server-Side Validation
Additional security measures:
- **Rate Limiting**: Maximum 10 submissions per 15 minutes per IP
- **Input Validation**: Comprehensive validation of all score data
- **Suspicious Pattern Detection**: Flags potentially fraudulent scores
- **Cross-Validation**: Verifies score consistency with performance metrics

### Production Security
For production deployment:
1. Change the `ENCODING_SECRET` to a strong, unique value
2. Use HTTPS with SSL/TLS certificates
3. Configure firewall rules
4. Set up database backups
5. Monitor logs for suspicious activity

## API Usage Examples

### Submit Highscore (JavaScript)
```javascript
const encoder = new RogueMineEncoder('your-secret-key');
const client = new RogueMineAPIClient('https://mine-api.12389012.xyz', 'your-secret-key');

try {
  const result = await client.submitHighscore('PlayerName', 1500, 120.5, 150, 5);
  console.log('Score submitted:', result);
} catch (error) {
  console.error('Submission failed:', error);
}
```

### Get Highscores (JavaScript)
```javascript
try {
  const scores = await client.getHighscores(10);
  console.log('Top scores:', scores.highscores);
} catch (error) {
  console.error('Failed to fetch scores:', error);
}
```

### Submit Highscore (GDScript)
```gdscript
# In your game scene
var api_client = RogueMineAPIClient.new("https://mine-api.12389012.xyz", "your-secret-key")
api_client.setup_http_request(self)
api_client.request_completed.connect(_on_score_submitted)

func submit_score():
    api_client.submit_highscore("PlayerName", 1500, 120.5, 150, 5)

func _on_score_submitted(success: bool, data: Dictionary):
    if success:
        print("Score submitted! Rank: ", data.rank)
    else:
        print("Submission failed: ", data.error)
```

## Testing

### Test Encoding Algorithm
```bash
cd backend
node test/test-encoding.js
```

### Test API Endpoints
```bash
# Health check
curl https://mine-api.12389012.xyz/health

# Get highscores
curl https://mine-api.12389012.xyz/api/highscores

# Submit score (requires encoded data)
curl -X POST https://mine-api.12389012.xyz/api/highscores \
  -H "Content-Type: application/json" \
  -d '{"encodedData": "your-encoded-data-here"}'
```

## Troubleshooting

### Common Issues

1. **Port already in use**
   - Change the `PORT` in `.env` file
   - Or stop the process using the port

2. **CORS errors**
   - Add your game's URL to `ALLOWED_ORIGINS` in `.env`
   - For Godot web exports, include the export URL

3. **Database errors**
   - Ensure the `database/` directory is writable
   - Check disk space

4. **Encoding/decoding errors**
   - Verify the secret key matches between client and server
   - Check that timestamps are within the 5-minute window

### Logs
Server logs include detailed information about:
- Request processing
- Encoding/decoding attempts
- Database operations
- Security violations

## Deployment

For production deployment, consider:
1. **Process Manager**: Use PM2 or similar for process management
2. **Reverse Proxy**: Use nginx or Apache for HTTPS and load balancing
3. **Database**: Consider PostgreSQL or MySQL for larger scale
4. **Monitoring**: Set up logging and monitoring solutions
5. **Backups**: Implement regular database backups

## Support

If you encounter issues:
1. Check the server logs for error messages
2. Verify your configuration in `.env`
3. Test the encoding algorithm with the test script
4. Ensure your firewall allows the configured port

The backend is designed to be robust and handle various edge cases, but proper configuration is essential for security and performance.
