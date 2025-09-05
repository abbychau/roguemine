const { calculateChecksum } = require('./src/encoding');

// Test with the exact data from the latest failure
const playerName = "abby";
const score = 1190;
const timeTaken = 0.55;
const tilesRevealed = 1;
const chordsPerformed = 0;
const timestamp = 1757084423891;

console.log('=== Verifying Checksum Calculation ===');
console.log('Data:');
console.log('Player:', playerName);
console.log('Score:', score);
console.log('Time:', timeTaken);
console.log('Tiles:', tilesRevealed);
console.log('Chords:', chordsPerformed);
console.log('Timestamp:', timestamp);

const correctChecksum = calculateChecksum(playerName, score, timeTaken, tilesRevealed, chordsPerformed, timestamp);
console.log('\nCorrect checksum (JavaScript):', correctChecksum);

const receivedChecksum = 1037722728;
console.log('Received checksum (GDScript):', receivedChecksum);
console.log('Match:', correctChecksum === receivedChecksum);

if (correctChecksum === receivedChecksum) {
    console.log('\n✅ Checksums match! The issue is elsewhere.');
} else {
    console.log('\n❌ Checksums don\'t match. GDScript hash function still needs fixing.');
    console.log('Difference:', correctChecksum - receivedChecksum);
}

// Let's also test if the issue is with the server's expected calculation
console.log('\n=== Server Expected vs Actual ===');
console.log('Server expected:', 1861887826);
console.log('JavaScript calculated:', correctChecksum);
console.log('GDScript sent:', receivedChecksum);

if (correctChecksum === receivedChecksum) {
    console.log('\nThe issue is that the server is calculating a different expected checksum.');
    console.log('This suggests there might be a bug in the server-side decoding logic.');
}
