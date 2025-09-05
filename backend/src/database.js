const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

let db = null;

/**
 * Initialize the SQLite database
 */
async function initializeDatabase() {
  return new Promise((resolve, reject) => {
    const dbPath = process.env.DB_PATH || './database/highscores.db';
    const dbDir = path.dirname(dbPath);
    
    // Create database directory if it doesn't exist
    if (!fs.existsSync(dbDir)) {
      fs.mkdirSync(dbDir, { recursive: true });
    }
    
    db = new sqlite3.Database(dbPath, (err) => {
      if (err) {
        console.error('Error opening database:', err);
        reject(err);
        return;
      }
      
      console.log('Connected to SQLite database');
      createTables()
        .then(resolve)
        .catch(reject);
    });
  });
}

/**
 * Create necessary tables
 */
function createTables() {
  return new Promise((resolve, reject) => {
    const createHighscoresTable = `
      CREATE TABLE IF NOT EXISTS highscores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        encoded_data TEXT NOT NULL,
        player_name TEXT NOT NULL,
        score INTEGER NOT NULL,
        time_taken REAL NOT NULL,
        tiles_revealed INTEGER NOT NULL,
        chords_performed INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        ip_address TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(encoded_data)
      )
    `;
    
    const createIndexes = [
      'CREATE INDEX IF NOT EXISTS idx_score ON highscores(score DESC)',
      'CREATE INDEX IF NOT EXISTS idx_timestamp ON highscores(timestamp)',
      'CREATE INDEX IF NOT EXISTS idx_created_at ON highscores(created_at)',
      'CREATE INDEX IF NOT EXISTS idx_player_name ON highscores(player_name)'
    ];
    
    db.run(createHighscoresTable, (err) => {
      if (err) {
        console.error('Error creating highscores table:', err);
        reject(err);
        return;
      }
      
      // Create indexes
      let indexPromises = createIndexes.map(indexSql => {
        return new Promise((resolveIndex, rejectIndex) => {
          db.run(indexSql, (err) => {
            if (err) {
              console.error('Error creating index:', err);
              rejectIndex(err);
            } else {
              resolveIndex();
            }
          });
        });
      });
      
      Promise.all(indexPromises)
        .then(() => {
          console.log('Database tables and indexes created successfully');
          resolve();
        })
        .catch(reject);
    });
  });
}

/**
 * Get database instance
 */
function getDatabase() {
  if (!db) {
    throw new Error('Database not initialized. Call initializeDatabase() first.');
  }
  return db;
}

/**
 * Close database connection
 */
function closeDatabase() {
  return new Promise((resolve, reject) => {
    if (db) {
      db.close((err) => {
        if (err) {
          reject(err);
        } else {
          console.log('Database connection closed');
          resolve();
        }
      });
    } else {
      resolve();
    }
  });
}

module.exports = {
  initializeDatabase,
  getDatabase,
  closeDatabase
};
