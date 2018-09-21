var http = require("http");
var url = require("url");
var fs = require('fs');
const querystring = require("querystring");
var path = require('path');
var formidable = require('formidable'),
  os = require('os'),
  util = require('util');
var config = require('./config').types; //
var netServerUrlFlag = require('./config').netServerUrlFlag;
var netServerhost = require('./config').netServerhost;
var netServerport = require('./config').netServerport;
var javaServerUrlFlag = require('./config').javaServerUrlFlag;
var javaServerhost = require('./config').javaServerhost;
var javaServerport = require('./config').javaServerport;
var fileServerUrlFlag = require('./config').fileServerUrlFlag;
var webapp = require('./config').webapp;
var PORT = require('./config').webport;
/**
 * 上传文件
 * @param files   经过formidable处理过的文件
 * @param req    httpRequest对象
 * @param postData  额外提交的数据
 */
function uploadFile(files, req, postData) {
  var boundaryKey = Math.random().toString(16);
  var endData = '\r\n----' + boundaryKey + '--';
  var filesLength = 0, content;
  // 初始数据，把post过来的数据都携带上去
  content = (function (obj) {
    var rslt = [];
    Object.keys(obj).forEach(function (key) {
      arr = ['\r\n----' + boundaryKey + '\r\n'];
      arr.push('Content-Disposition: form-data; name="' + obj[key][0] + '"\r\n\r\n');
      arr.push(obj[key][1]);
      rslt.push(arr.join(''));
    });
    return rslt.join('');
  })(postData); 
  // 组装数据
  Object.keys(files).forEach(function (key) {
    if (!files.hasOwnProperty(key)) {
      delete files.key;
      return;
    }
    content += '\r\n----' + boundaryKey + '\r\n' +
      'Content-Type: application/octet-stream\r\n' +
      'Content-Disposition: form-data; name="' + files[key][0] + '"; ' +
      'filename="' + files[key][1].name + '"; \r\n' +
      'Content-Transfer-Encoding: binary\r\n\r\n';
    files[key].contentBinary = new Buffer(content, 'utf-8');;
    filesLength += files[key].contentBinary.length + fs.statSync(files[key][1].path).size;
  });
  req.setHeader('Content-Type', 'multipart/form-data; boundary=--' + boundaryKey);
  req.setHeader('Content-Length', filesLength + Buffer.byteLength(endData));
  // 执行上传
  var allFiles = Object.keys(files);
  var fileNum = allFiles.length;
  var uploadedCount = 0;
  allFiles.forEach(function (key) {
    req.write(files[key].contentBinary);
    console.log("files[key].path:" + files[key][1].path);
    var fileStream = fs.createReadStream(files[key][1].path, { bufferSize: 4 * 1024 });
    fileStream.on('end', function () {
      // 上传成功一个文件之后，把临时文件删了
      fs.unlink(files[key][1].path);
      uploadedCount++;
      if (uploadedCount == fileNum) {
        // 如果已经是最后一个文件，那就正常结束
        req.end(endData);
      }
    });
    fileStream.pipe(req, { end: false });
  });
}
var server = http.createServer(function (request, response) {
  var clientUrl = request.url;
  var url_parts = url.parse(clientUrl); //解析路径
  var pathname = url_parts.pathname;
  var sreq = request;
  var sres = response;
  // .net 转发请求
  if (pathname.match(netServerUrlFlag) != null) {
    var clientUrl2 = clientUrl.replace("/" + netServerUrlFlag, '');
    console.log(".net转发请求......" + clientUrl2);
    var pramsJson = '';
    sreq.on("data", function (data) {
      pramsJson += data;
    }).on("end", function () {
      var contenttype = request.headers['content-type'];
      if (contenttype == undefined || contenttype == null || contenttype == '') {
        var opt = {
          host: netServerhost, //跨域访问的主机ip
          port: netServerport,
          path: clientUrl2,
          method: request.method,
          headers: {
            'Content-Length': Buffer.byteLength(pramsJson)
          }
        }
      } else {
        var opt = {
          host: netServerhost, //跨域访问的主机ip
          port: netServerport,
          path: clientUrl2,
          method: request.method,
          headers: {
            'Content-Type': request.headers['content-type'],
            'Content-Length': Buffer.byteLength(pramsJson)
          }
        }
      }
      console.log('method', opt.method);
      var body = '';
      var req = http.request(opt, function (res) {
        res.on('data', function (data) {
          body += data;
        }).on('end', function () {
          response.write(body);
          response.end();
        });
      }).on('error', function (e) {
        response.end('内部错误，请联系管理员！MSG:' + e);
        console.log("error: " + e.message);
      })
      req.write(pramsJson);
      req.end();
    })
  } else
    // java 转发请求
    if (pathname.match(javaServerUrlFlag) != null) {
      response.setHeader("Content-type", "text/plain;charset=UTF-8");
      var clientUrl2 = clientUrl.replace("/" + javaServerUrlFlag, '');
      console.log(".java转发请求......http://" + javaServerhost + ":" + javaServerport + "" + clientUrl2);
      var prams = '';
      sreq.on("data", function (data) {
        prams += data;
      }).on("end", function () {
        console.log("client pramsJson>>>>>" + prams);
        const postData = prams;
        console.log("client pramsJson>>>>>" + postData);
        var contenttype = request.headers['content-type'];
        if (contenttype == undefined || contenttype == null || contenttype == '') {
          var opt = {
            host: javaServerhost, //跨域访问的主机ip
            port: javaServerport,
            path: "/hrrp" + clientUrl2,
            method: request.method,
            headers: {
              'Content-Length': Buffer.byteLength(postData)
            }
          }
        } else {
          var opt = {
            host: javaServerhost, //跨域访问的主机ip
            port: javaServerport,
            path: "/hrrp" + clientUrl2,
            method: request.method,
            headers: {
              'Content-Type': request.headers['content-type'],
              'Content-Length': Buffer.byteLength(postData)
            }
          }
        }
        var body = '';
        console.log('method', opt.method);
        var req = http.request(opt, function (res) {
          //console.log("response: " + res.statusCode);
          res.on('data', function (data) {
            body += data;
          }).on('end', function () {
            response.write(body);
            response.end();
            //console.log("end:>>>>>>>" + body);
          });
        }).on('error', function (e) {
          response.end('内部错误，请联系管理员！MSG:' + e);
          console.log("error: " + e.message);
        })
        req.write(postData);
        req.end();
      })
    } else if (pathname.match(fileServerUrlFlag) != null) {
      //文件拦截保存到本地
      var form = new formidable.IncomingForm(),
        files = [],
        fields = [];
      form.uploadDir = os.tmpdir();
      form.on('field', function (field, value) {
        console.log(field, value);
        fields.push([field, value]);
      }).on('file', function (field, file) {
        console.log(field, file);
        files.push([field, file]);
      }).on('end', function () {
        //
        var clientUrl2 = clientUrl.replace("/" + fileServerUrlFlag, '');
        var opt = {
          host: netServerhost, //跨域访问的主机ip
          port: netServerport,
          path: clientUrl2,
          method: request.method
        }
        var body = '';
        var req = http.request(opt, function (res) {
          res.on('data', function (data) {
            body += data;
          }).on('end', function () {
            response.write(body);
            response.end();
          });
        }).on('error', function (e) {
          response.end('内部错误，请联系管理员！MSG:' + e);
          console.log("error: " + e.message);
        })
        //文件上传
        uploadFile(files, req, fields);
      });
      form.parse(sreq);
    }
    else {
      var realPath = path.join(webapp, pathname); //这里设置自己的文件名称;
      var ext = path.extname(realPath);
      ext = ext ? ext.slice(1) : 'unknown';
      fs.exists(realPath, function (exists) {
        //console.log("file is exists："+exists+" file path: " + realPath + "");
        if (!exists) {
          response.writeHead(404, {
            'Content-Type': 'text/plain'
          });
          response.write("This request URL " + pathname + " was not found on this server.");
          response.end();
        } else {
          fs.readFile(realPath, "binary", function (err, file) {
            if (err) {
              response.writeHead(500, {
                'Content-Type': 'text/plain'
              });
              //response.end(err);
              response.end("内部错误，请联系管理员");
            } else {
              var contentType = config[ext] || "text/plain";
              response.writeHead(200, {
                'Content-Type': contentType
              });
              response.write(file, "binary");
              response.end();
            }
          });
        }
      });
    }
});
server.listen(PORT);
console.log("Server runing at port: " + PORT + ".");
