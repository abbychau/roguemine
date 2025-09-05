const { calculateChecksum, simpleHash } = require('./src/encoding');

// Test the checksum calculation with known values
const secret = "roguemine-secret-key-2024-change-in-production";

console.log('=== Testing Checksum Calculation ===');

// Test simple hash function
const testString = "test";
const hash = simpleHash(testString);
console.log('Simple hash of "test":', hash);

// Test with the actual data string from the failed case
const failedDataString = "abby|4209|2.24|62|0|1757083807877roguemine-secret-key-2024-change-in-production";
const failedHash = simpleHash(failedDataString);
console.log('Hash of failed data string:', failedHash);

// Test with the latest failed data string
const latestFailedString = "abby|1761|4.41|24|0|1757084197182roguemine-secret-key-2024-change-in-production";
const latestFailedHash = simpleHash(latestFailedString);
console.log('Hash of latest failed data string:', latestFailedHash);

// Test checksum with sample data
const playerName = "Player";
const score = 2923;
const timeTaken = 120.5;
const tilesRevealed = 150;
const chordsPerformed = 5;
const timestamp = 1757083807877;

console.log('\nTest data:');
console.log('Player:', playerName);
console.log('Score:', score);
console.log('Time:', timeTaken);
console.log('Tiles:', tilesRevealed);
console.log('Chords:', chordsPerformed);
console.log('Timestamp:', timestamp);
console.log('Secret:', secret);

const checksum = calculateChecksum(playerName, score, timeTaken, tilesRevealed, chordsPerformed, timestamp);
console.log('\nCalculated checksum:', checksum);

// Test the data string format
const dataString = `${playerName}|${score}|${timeTaken}|${tilesRevealed}|${chordsPerformed}|${timestamp}`;
console.log('\nData string:', dataString);
console.log('Data string + secret:', dataString + secret);
console.log('Hash of combined string:', simpleHash(dataString + secret));

// Test with different time formatting
const timeAsString = String(timeTaken);
const dataStringAlt = `${playerName}|${score}|${timeAsString}|${tilesRevealed}|${chordsPerformed}|${timestamp}`;
console.log('\nAlternative data string:', dataStringAlt);
console.log('Alternative checksum:', simpleHash(dataStringAlt + secret));
