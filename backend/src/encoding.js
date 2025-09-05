const crypto = require('crypto');

/**
 * Custom encoding/decoding system for RogueMine highscores
 * 
 * Security layers:
 * 1. Data validation and normalization
 * 2. Timestamp verification (prevents replay attacks)
 * 3. Checksum calculation (prevents data tampering)
 * 4. XOR cipher with rotating key (obfuscation)
 * 5. Base64 encoding (transport safety)
 * 
 * The algorithm is designed to be implementable in both JavaScript and GDScript
 */

const ENCODING_SECRET = process.env.ENCODING_SECRET || 'default-secret-key';
const MAX_TIMESTAMP_AGE = 5 * 60 * 1000; // 5 minutes in milliseconds

/**
 * Generate a simple hash from a string (compatible with GDScript)
 */
function simpleHash(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convert to 32-bit integer
  }
  return Math.abs(hash);
}

/**
 * Generate XOR key based on secret and timestamp
 */
function generateXORKey(timestamp, secret) {
  const combined = secret + timestamp.toString();
  const hash = simpleHash(combined);
  
  // Generate a repeating key pattern
  const keyLength = 16;
  const key = [];
  
  for (let i = 0; i < keyLength; i++) {
    key.push((hash + i * 7) % 256);
  }
  
  return key;
}

/**
 * XOR encrypt/decrypt data with rotating key
 */
function xorCipher(data, key) {
  const result = [];
  for (let i = 0; i < data.length; i++) {
    const keyIndex = i % key.length;
    result.push(data[i] ^ key[keyIndex]);
  }
  return result;
}

/**
 * Calculate checksum for data integrity
 */
function calculateChecksum(playerName, score, timeTaken, tilesRevealed, chordsPerformed, timestamp) {
  const dataString = `${playerName}|${score}|${timeTaken}|${tilesRevealed}|${chordsPerformed}|${timestamp}`;
  return simpleHash(dataString + ENCODING_SECRET);
}

/**
 * Convert string to byte array
 */
function stringToBytes(str) {
  const bytes = [];
  for (let i = 0; i < str.length; i++) {
    bytes.push(str.charCodeAt(i));
  }
  return bytes;
}

/**
 * Convert byte array to string
 */
function bytesToString(bytes) {
  return String.fromCharCode(...bytes);
}

/**
 * Encode highscore data
 */
function encodeHighscore(playerName, score, timeTaken, tilesRevealed, chordsPerformed) {
  try {
    // Validate input data
    if (!playerName || typeof playerName !== 'string') {
      throw new Error('Invalid player name');
    }
    if (!Number.isInteger(score) || score < 0) {
      throw new Error('Invalid score');
    }
    if (typeof timeTaken !== 'number' || timeTaken < 0) {
      throw new Error('Invalid time taken');
    }
    if (!Number.isInteger(tilesRevealed) || tilesRevealed < 0) {
      throw new Error('Invalid tiles revealed');
    }
    if (!Number.isInteger(chordsPerformed) || chordsPerformed < 0) {
      throw new Error('Invalid chords performed');
    }
    
    // Normalize data
    playerName = playerName.trim().substring(0, 50); // Limit name length
    score = Math.floor(score);
    timeTaken = Math.round(timeTaken * 100) / 100; // Round to 2 decimal places
    tilesRevealed = Math.floor(tilesRevealed);
    chordsPerformed = Math.floor(chordsPerformed);
    
    // Generate timestamp
    const timestamp = Date.now();
    
    // Calculate checksum
    const checksum = calculateChecksum(playerName, score, timeTaken, tilesRevealed, chordsPerformed, timestamp);
    
    // Create data object
    const dataObj = {
      n: playerName,      // name
      s: score,           // score
      t: timeTaken,       // time
      r: tilesRevealed,   // tiles revealed
      c: chordsPerformed, // chords
      ts: timestamp,      // timestamp
      cs: checksum        // checksum
    };
    
    // Convert to JSON string
    const jsonString = JSON.stringify(dataObj);
    
    // Convert to bytes
    const dataBytes = stringToBytes(jsonString);
    
    // Generate XOR key
    const xorKey = generateXORKey(timestamp, ENCODING_SECRET);
    
    // Apply XOR cipher
    const encryptedBytes = xorCipher(dataBytes, xorKey);
    
    // Convert to base64
    const base64Data = Buffer.from(encryptedBytes).toString('base64');
    
    return {
      success: true,
      encodedData: base64Data,
      timestamp: timestamp
    };
    
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * Decode highscore data
 */
function decodeHighscore(encodedData) {
  try {
    // Decode from base64
    const encryptedBytes = Array.from(Buffer.from(encodedData, 'base64'));
    
    // We need to try different timestamps since we don't know the exact one
    // In practice, the client should send the timestamp separately or we store it
    const currentTime = Date.now();
    let decoded = null;
    
    // Try timestamps within the last 5 minutes
    for (let offset = 0; offset <= MAX_TIMESTAMP_AGE; offset += 1000) {
      const testTimestamp = currentTime - offset;
      
      try {
        const xorKey = generateXORKey(testTimestamp, ENCODING_SECRET);
        const decryptedBytes = xorCipher(encryptedBytes, xorKey);
        const jsonString = bytesToString(decryptedBytes);
        const dataObj = JSON.parse(jsonString);
        
        // Verify timestamp is within acceptable range
        if (Math.abs(dataObj.ts - testTimestamp) < 1000) {
          decoded = dataObj;
          break;
        }
      } catch (e) {
        // Continue trying other timestamps
        continue;
      }
    }
    
    if (!decoded) {
      throw new Error('Failed to decode data - invalid or expired');
    }
    
    // Verify checksum
    const expectedChecksum = calculateChecksum(
      decoded.n, decoded.s, decoded.t, decoded.r, decoded.c, decoded.ts
    );
    
    if (decoded.cs !== expectedChecksum) {
      throw new Error('Data integrity check failed');
    }
    
    // Verify timestamp age
    const age = Date.now() - decoded.ts;
    if (age > MAX_TIMESTAMP_AGE) {
      throw new Error('Data too old');
    }
    
    return {
      success: true,
      data: {
        playerName: decoded.n,
        score: decoded.s,
        timeTaken: decoded.t,
        tilesRevealed: decoded.r,
        chordsPerformed: decoded.c,
        timestamp: decoded.ts
      }
    };
    
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}

module.exports = {
  encodeHighscore,
  decodeHighscore,
  simpleHash,
  generateXORKey,
  xorCipher,
  calculateChecksum,
  stringToBytes,
  bytesToString
};
