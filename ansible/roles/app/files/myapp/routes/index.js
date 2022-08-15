var express = require('express');
var router = express.Router();
var await = require('asyncawait/await');

var Netmask = require('netmask').Netmask
var CIDR = process.env.APPL_CIDR;
var block = new Netmask(CIDR);

const { Client } = require('pg')
const client = new Client()
client.connect()

var addresses = [];
var os = require('os');
var ifaces = os.networkInterfaces();
Object.keys(ifaces).forEach(function (ifname) {
  ifaces[ifname].forEach(function (iface) {
    if ('IPv4' !== iface.family || iface.internal !== false) {
      // skip over internal (i.e. 127.0.0.1) and non-ipv4 addresses
      return;
    }
    addresses.push(iface.address);
  });
});

/* GET home page. */
router.get('/', function(req, res, next) {
  console.log(req.query)
  if ("app_name" in req.query) {
    console.log("app_name")
    client.query('UPDATE app SET data = $1', [req.query["app_name"]], (err, dbres) => {
      console.log(err ? err.stack : dbres)
      client.query('SELECT * FROM app', [], (err, dbres) => {
        console.log(err ? err.stack : dbres.rows[0].data)
        addressChecker = function (addresses) {
          for (var index in addresses) {
            if (block.contains(addresses[index])) {
              return true;
            }
          }
          return false;
        }
        if (!addressChecker(addresses)) {
          res.status(500).send("IP address not in CIDR block!");
        } else {
          res.render('index', { title: dbres.rows[0].data });
        }
      })
    })
  } else {
    client.query('SELECT * FROM app', [], (err, dbres) => {
      console.log(err ? err.stack : dbres.rows[0].data)
      addressChecker = function (addresses) {
        for (var index in addresses) {
          if (block.contains(addresses[index])) {
            return true;
          }
        }
        return false;
      }
      if (!addressChecker(addresses)) {
        res.status(500).send("IP address not in CIDR block!");
      } else {
        res.render('index', { title: dbres.rows[0].data });
      }
    })
  }
});

module.exports = router;
