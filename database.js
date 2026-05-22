const mysql = require('mysql2');
require('dotenv').config();

const connection = mysql.createConnection({
  host: '127.0.0.1',
  user: 'root',
  password: '',
  database: 'TIMERCAFEDB',
  port: 8080
});

connection.connect(error => {
  if (error) throw error;
  console.log("✅ Conectado");
});

module.exports = connection;
