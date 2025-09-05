/**
 * Test script for RogueMine encoding/decoding functionality
 * Run with: node test/test-encoding.js
 */

const { encodeHighscore, decodeHighscore } = require('../src/encoding');

console.log('=== RogueMine Encoding Test ===\n');

// Test data
const testCases = [
  {
    name: 'Normal Score',
    playerName: 'TestPlayer',
    score: 1500,
    timeTaken: 120.5,
    tilesRevealed: 150,
    chordsPerformed: 5
  },
  {
    name: 'High Score',
    playerName: 'ProGamer',
    score: 50000,
    timeTaken: 300.25,
    tilesRevealed: 1000,
    chordsPerformed: 25
  },
  {
    name: 'Quick Game',
    playerName: 'SpeedRunner',
    score: 800,
    timeTaken: 45.0,
    tilesRevealed: 80,
    chordsPerformed: 2
  }
];

async function runTests() {
  for (const testCase of testCases) {
    console.log(`Testing: ${testCase.name}`);
    console.log(`Input: ${JSON.stringify(testCase, null, 2)}`);
    
    // Test encoding
    const encodeResult = encodeHighscore(
      testCase.playerName,
      testCase.score,
      testCase.timeTaken,
      testCase.tilesRevealed,
      testCase.chordsPerformed
    );
    
    if (!encodeResult.success) {
      console.error('❌ Encoding failed:', encodeResult.error);
      continue;
    }
    
    console.log('✅ Encoding successful');
    console.log(`Encoded data: ${encodeResult.encodedData.substring(0, 50)}...`);
    
    // Test decoding
    const decodeResult = decodeHighscore(encodeResult.encodedData);
    
    if (!decodeResult.success) {
      console.error('❌ Decoding failed:', decodeResult.error);
      continue;
    }
    
    console.log('✅ Decoding successful');
    console.log(`Decoded data: ${JSON.stringify(decodeResult.data, null, 2)}`);
    
    // Verify data integrity
    const original = testCase;
    const decoded = decodeResult.data;
    
    const isValid = (
      original.playerName === decoded.playerName &&
      original.score === decoded.score &&
      Math.abs(original.timeTaken - decoded.timeTaken) < 0.01 &&
      original.tilesRevealed === decoded.tilesRevealed &&
      original.chordsPerformed === decoded.chordsPerformed
    );
    
    if (isValid) {
      console.log('✅ Data integrity verified');
    } else {
      console.error('❌ Data integrity check failed');
      console.log('Expected:', original);
      console.log('Got:', decoded);
    }
    
    console.log('---\n');
  }
  
  // Test invalid data
  console.log('Testing invalid data...');
  
  const invalidTests = [
    { playerName: '', score: 1000, timeTaken: 120, tilesRevealed: 100, chordsPerformed: 5 },
    { playerName: 'Test', score: -100, timeTaken: 120, tilesRevealed: 100, chordsPerformed: 5 },
    { playerName: 'Test', score: 1000, timeTaken: -10, tilesRevealed: 100, chordsPerformed: 5 },
    { playerName: 'Test', score: 1000, timeTaken: 120, tilesRevealed: -50, chordsPerformed: 5 },
    { playerName: 'Test', score: 1000, timeTaken: 120, tilesRevealed: 100, chordsPerformed: -1 }
  ];
  
  for (const invalidTest of invalidTests) {
    const result = encodeHighscore(
      invalidTest.playerName,
      invalidTest.score,
      invalidTest.timeTaken,
      invalidTest.tilesRevealed,
      invalidTest.chordsPerformed
    );
    
    if (result.success) {
      console.error('❌ Should have failed for invalid data:', invalidTest);
    } else {
      console.log('✅ Correctly rejected invalid data:', result.error);
    }
  }
  
  // Test tampered data
  console.log('\nTesting tampered data...');
  
  const originalEncode = encodeHighscore('TestPlayer', 1000, 120, 100, 5);
  if (originalEncode.success) {
    // Tamper with the encoded data
    let tamperedData = originalEncode.encodedData;
    tamperedData = tamperedData.substring(0, tamperedData.length - 5) + 'XXXXX';
    
    const decodeResult = decodeHighscore(tamperedData);
    if (decodeResult.success) {
      console.error('❌ Should have failed for tampered data');
    } else {
      console.log('✅ Correctly rejected tampered data:', decodeResult.error);
    }
  }
  
  console.log('\n=== Test Complete ===');
}

runTests().catch(console.error);
