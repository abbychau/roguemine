/**
 * Client-side encoding library for RogueMine highscores
 * Compatible with browser environments and can be adapted for Godot
 * 
 * This mirrors the server-side encoding algorithm
 */

class RogueMineEncoder {
  constructor(secret = 'default-secret-key') {
    this.secret = secret;
    this.maxTimestampAge = 5 * 60 * 1000; // 5 minutes
  }
  
  /**
   * Generate a simple hash from a string (compatible with GDScript)
   */
  simpleHash(str) {
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
  generateXORKey(timestamp, secret) {
    const combined = secret + timestamp.toString();
    const hash = this.simpleHash(combined);
    
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
  xorCipher(data, key) {
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
  calculateChecksum(playerName, score, timeTaken, tilesRevealed, chordsPerformed, timestamp) {
    const dataString = `${playerName}|${score}|${timeTaken}|${tilesRevealed}|${chordsPerformed}|${timestamp}`;
    return this.simpleHash(dataString + this.secret);
  }
  
  /**
   * Convert string to byte array
   */
  stringToBytes(str) {
    const bytes = [];
    for (let i = 0; i < str.length; i++) {
      bytes.push(str.charCodeAt(i));
    }
    return bytes;
  }
  
  /**
   * Convert byte array to string
   */
  bytesToString(bytes) {
    return String.fromCharCode(...bytes);
  }
  
  /**
   * Base64 encode (browser compatible)
   */
  base64Encode(bytes) {
    if (typeof btoa !== 'undefined') {
      // Browser environment
      return btoa(String.fromCharCode(...bytes));
    } else {
      // Node.js environment
      return Buffer.from(bytes).toString('base64');
    }
  }
  
  /**
   * Base64 decode (browser compatible)
   */
  base64Decode(base64String) {
    if (typeof atob !== 'undefined') {
      // Browser environment
      const str = atob(base64String);
      const bytes = [];
      for (let i = 0; i < str.length; i++) {
        bytes.push(str.charCodeAt(i));
      }
      return bytes;
    } else {
      // Node.js environment
      return Array.from(Buffer.from(base64String, 'base64'));
    }
  }
  
  /**
   * Encode highscore data
   */
  encodeHighscore(playerName, score, timeTaken, tilesRevealed, chordsPerformed) {
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
      const checksum = this.calculateChecksum(playerName, score, timeTaken, tilesRevealed, chordsPerformed, timestamp);
      
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
      const dataBytes = this.stringToBytes(jsonString);
      
      // Generate XOR key
      const xorKey = this.generateXORKey(timestamp, this.secret);
      
      // Apply XOR cipher
      const encryptedBytes = this.xorCipher(dataBytes, xorKey);
      
      // Convert to base64
      const base64Data = this.base64Encode(encryptedBytes);
      
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
  decodeHighscore(encodedData) {
    try {
      // Decode from base64
      const encryptedBytes = this.base64Decode(encodedData);
      
      // We need to try different timestamps since we don't know the exact one
      const currentTime = Date.now();
      let decoded = null;
      
      // Try timestamps within the last 5 minutes
      for (let offset = 0; offset <= this.maxTimestampAge; offset += 1000) {
        const testTimestamp = currentTime - offset;
        
        try {
          const xorKey = this.generateXORKey(testTimestamp, this.secret);
          const decryptedBytes = this.xorCipher(encryptedBytes, xorKey);
          const jsonString = this.bytesToString(decryptedBytes);
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
      const expectedChecksum = this.calculateChecksum(
        decoded.n, decoded.s, decoded.t, decoded.r, decoded.c, decoded.ts
      );
      
      if (decoded.cs !== expectedChecksum) {
        throw new Error('Data integrity check failed');
      }
      
      // Verify timestamp age
      const age = Date.now() - decoded.ts;
      if (age > this.maxTimestampAge) {
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
}

// Export for different environments
if (typeof module !== 'undefined' && module.exports) {
  // Node.js environment
  module.exports = RogueMineEncoder;
} else if (typeof window !== 'undefined') {
  // Browser environment
  window.RogueMineEncoder = RogueMineEncoder;
}
