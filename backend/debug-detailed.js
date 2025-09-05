const { decodeHighscore, calculateChecksum, simpleHash, generateXORKey, xorCipher, stringToBytes, bytesToString } = require('./src/encoding');

const ENCODING_SECRET = process.env.ENCODING_SECRET || 'roguemine-secret-key-2024-change-in-production';

// Test the latest problematic encoded data from Godot
const latestGodotData = "pMSO1sEyJTJ0bQcWAgpyf+jU38PJOiUyeTwfDlJYIzH9ys+G2Tg4PDVtBxYCC3h488SZ1sEyJyUiMgdYQBh7eejT2sTDNj0iJCYcHU4=";

console.log('=== Detailed Decoding Analysis ===');
console.log('Encoded data:', latestGodotData);
console.log('Secret:', ENCODING_SECRET);

// Decode from base64
const encryptedBytes = Array.from(Buffer.from(latestGodotData, 'base64'));
console.log('Encrypted bytes length:', encryptedBytes.length);

// Try different timestamps to find the right one
const currentTime = Date.now();
console.log('Current time:', currentTime);

let foundData = null;
let foundOffset = null;

for (let offset = 0; offset <= 30 * 60 * 1000; offset += 1000) {
  const testTimestamp = currentTime - offset;
  
  try {
    const xorKey = generateXORKey(testTimestamp, ENCODING_SECRET);
    const decryptedBytes = xorCipher(encryptedBytes, xorKey);
    const jsonString = bytesToString(decryptedBytes);
    const dataObj = JSON.parse(jsonString);
    
    if (dataObj && typeof dataObj === 'object' && 
        dataObj.hasOwnProperty('n') && dataObj.hasOwnProperty('s') && 
        dataObj.hasOwnProperty('ts') && dataObj.hasOwnProperty('cs')) {
      console.log('\nFound valid data at offset:', offset);
      console.log('Test timestamp:', testTimestamp);
      console.log('Data timestamp:', dataObj.ts);
      console.log('Decoded object:', dataObj);
      
      // Calculate expected checksum
      const expectedChecksum = calculateChecksum(
        dataObj.n, dataObj.s, dataObj.t, dataObj.r, dataObj.c, dataObj.ts
      );
      
      console.log('Expected checksum:', expectedChecksum);
      console.log('Actual checksum:', dataObj.cs);
      console.log('Checksums match:', expectedChecksum === dataObj.cs);
      
      // Show the data string used for checksum
      const dataString = `${dataObj.n}|${dataObj.s}|${dataObj.t}|${dataObj.r}|${dataObj.c}|${dataObj.ts}`;
      console.log('Data string for checksum:', dataString);
      console.log('Data string + secret length:', (dataString + ENCODING_SECRET).length);
      
      foundData = dataObj;
      foundOffset = offset;
      break;
    }
  } catch (e) {
    // Continue trying
  }
}

if (!foundData) {
  console.log('No valid data found in any timestamp range');
} else {
  console.log('\n=== Final Analysis ===');
  console.log('Data was encoded at timestamp:', foundData.ts);
  console.log('Time difference from now:', currentTime - foundData.ts, 'ms');
  console.log('That\'s', Math.round((currentTime - foundData.ts) / 1000), 'seconds ago');
}
