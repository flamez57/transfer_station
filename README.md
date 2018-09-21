# 使用node.js搭建服务器

1、创建demo.js文件，首先通过require()获取服务器模块，接着通过createServer方法创建服务器，通过console.log在控制台打印出日志信息。
```javascript 
var http = require('http');  
http.createServer(function (request, response) {  
    response.writeHead(200, {'Content-Type': 'text/plain'});  
    response.end('Hello World\n');  
}).listen(8888);  
console.log('Server running at http://127.0.0.1:8888/');  
```
2、通过控制台编译,首先进入目标js所在目录，因为我放的目录结构为E:node/demo.js，所以通过cd找到指定文件，再通过node demo.js 编译目标
js文件，可看到控制台输出：Server running at http://127.0.0.1:8888/

3、打开浏览器地址：http://127.0.0.1:8888/，成功输出“Hello World”

至此，node.js服务器很轻松地搭建完毕，但是其中需要注意的一些地方在这里提一下：

1、你可能会问 response.writeHead(200, {'Content-Type': 'text/plain'}); 这里的200 表示什么？

其实200是服务器执行后返回值“OK”的状态码，大家可以在控制台输入 require ("http") 便可以得到如下图所示的所有帮助信息，省去查文档的麻烦

2、http.createServer(function (request, response) {}).listen(8888);此处listen中的“8888”是端口号可以随意但要和常用的“8080”端口
区别开，以防冲突。

3、如果是初次使用node.js 进行编译，你可能会遇到下列错误，但是不要害怕，这是因为你可能把js的文件名打错或者没有进入目标文件所在目录进行编译
