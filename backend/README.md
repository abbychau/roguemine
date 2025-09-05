# RogueMine Highscore Backend

A secure Node.js backend for managing RogueMine game highscores with custom encoding to prevent data forgery.

## Features

- **Custom Encoding Algorithm**: Multi-layered security with XOR cipher, checksums, and timestamp validation
- **SQLite Database**: Lightweight database with proper indexing for performance
- **Rate Limiting**: Prevents spam and abuse
- **CORS Support**: Configurable cross-origin resource sharing
- **Input Validation**: Server-side validation to prevent invalid data
- **Duplicate Prevention**: Prevents submission of identical scores

## Security Layers

1. **Data Validation**: Input sanitization and range checking
2. **Timestamp Verification**: Prevents replay attacks (5-minute window)
3. **Checksum Calculation**: Detects data tampering
4. **XOR Cipher**: Obfuscates data with rotating key
5. **Base64 Encoding**: Safe transport encoding

## Installation

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Copy environment configuration:
   ```bash
   cp .env.example .env
   ```

4. Edit `.env` file with your configuration:
   ```
   PORT=3000
   ENCODING_SECRET=your-secret-key-here
   ALLOWED_ORIGINS=http://localhost:8080
   ```

5. Start the server:
   ```bash
   npm start
   ```

   For development with auto-reload:
   ```bash
   npm run dev
   ```

## API Endpoints

### Health Check
- **GET** `/health`
- Returns server status and version

### Submit Highscore
- **POST** `/api/highscores`
- Body: `{ "encodedData": "base64-encoded-data" }`
- Returns: `{ "success": true, "rank": 1, "isTopScore": true }`

### Get Highscores
- **GET** `/api/highscores?limit=10`
- Returns: `{ "success": true, "highscores": [...], "totalCount": 50 }`

### Check Score
- **POST** `/api/highscores/check`
- Body: `{ "score": 1000, "timeTaken": 120.5 }`
- Returns: `{ "success": true, "rank": 5, "isTopScore": true }`

## Database Schema

### highscores table
```sql
CREATE TABLE highscores (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  encoded_data TEXT NOT NULL UNIQUE,
  player_name TEXT NOT NULL,
  score INTEGER NOT NULL,
  time_taken REAL NOT NULL,
  tiles_revealed INTEGER NOT NULL,
  chords_performed INTEGER NOT NULL,
  timestamp INTEGER NOT NULL,
  ip_address TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Indexes
- `idx_score`: Score descending for leaderboard queries
- `idx_timestamp`: Timestamp for cleanup operations
- `idx_created_at`: Creation date for analytics
- `idx_player_name`: Player name for player-specific queries

## Client Libraries

### JavaScript (Browser/Node.js)
```javascript
const encoder = new RogueMineEncoder('your-secret-key');
const client = new RogueMineAPIClient('http://localhost:3000', 'your-secret-key');

// Submit score
await client.submitHighscore('Player', 1000, 120.5, 50, 5);

// Get highscores
const scores = await client.getHighscores(10);
```

### GDScript (Godot)
```gdscript
var encoder = RogueMineEncoder.new("your-secret-key")
var client = RogueMineAPIClient.new("http://localhost:3000", "your-secret-key")

# Setup HTTP request (call from scene)
client.setup_http_request(self)

# Connect signals
client.request_completed.connect(_on_request_completed)
client.connection_error.connect(_on_connection_error)

# Submit score
client.submit_highscore("Player", 1000, 120.5, 50, 5)
```

## Security Considerations

1. **Change the default secret**: Update `ENCODING_SECRET` in production
2. **Use HTTPS**: Deploy with SSL/TLS encryption
3. **Rate limiting**: Configure appropriate limits for your use case
4. **Input validation**: Server validates all data regardless of client encoding
5. **Database backup**: Regular backups of the SQLite database

## Development

### Testing Endpoints (Development Only)
- **POST** `/api/highscores/test-encode`: Test encoding function
- **POST** `/api/highscores/test-decode`: Test decoding function

### Running Tests
```bash
npm test
```

### Database Management
The database is automatically created on first run. To reset:
```bash
rm database/highscores.db
```

## Deployment

1. Set `NODE_ENV=production` in environment
2. Use a process manager like PM2:
   ```bash
   npm install -g pm2
   pm2 start server.js --name roguemine-backend
   ```
3. Configure reverse proxy (nginx/Apache) for HTTPS
4. Set up database backups
5. Monitor logs and performance

## Troubleshooting

### Common Issues

1. **CORS errors**: Check `ALLOWED_ORIGINS` in `.env`
2. **Database locked**: Ensure only one server instance is running
3. **Encoding errors**: Verify secret key matches between client and server
4. **Rate limiting**: Check if requests are being throttled

### Logs
Server logs include:
- Request details
- Encoding/decoding attempts
- Database operations
- Error messages

## License

MIT License - see LICENSE file for details
