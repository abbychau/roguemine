const { encodeHighscore, decodeHighscore } = require('./src/encoding');

console.log('=== Testing Fresh Encoding (Simulating Fixed GDScript) ===');

// Simulate what the fixed GDScript should produce
const playerName = "TestPlayer";
const score = 1500;
const timeTaken = 90.5;
const tilesRevealed = 120;
const chordsPerformed = 3;

console.log('Test data:');
console.log('Player:', playerName);
console.log('Score:', score);
console.log('Time:', timeTaken);
console.log('Tiles:', tilesRevealed);
console.log('Chords:', chordsPerformed);

// Encode with JavaScript (this should match what fixed GDScript produces)
const encodeResult = encodeHighscore(playerName, score, timeTaken, tilesRevealed, chordsPerformed);

if (encodeResult.success) {
  console.log('\nEncoding successful!');
  console.log('Encoded data:', encodeResult.encodedData);
  
  // Test immediate decoding
  const decodeResult = decodeHighscore(encodeResult.encodedData);
  
  if (decodeResult.success) {
    console.log('\nDecoding successful!');
    console.log('Decoded data:', decodeResult.data);
    console.log('Data matches:', 
      decodeResult.data.playerName === playerName &&
      decodeResult.data.score === score &&
      Math.abs(decodeResult.data.timeTaken - timeTaken) < 0.01 &&
      decodeResult.data.tilesRevealed === tilesRevealed &&
      decodeResult.data.chordsPerformed === chordsPerformed
    );
  } else {
    console.log('\nDecoding failed:', decodeResult.error);
  }
} else {
  console.log('\nEncoding failed:', encodeResult.error);
}

console.log('\n=== Summary ===');
console.log('The fix should make new score submissions work correctly.');
console.log('Old encoded data may still fail because it was created with the wrong hash function.');
console.log('Players should submit new scores to test the fix.');
