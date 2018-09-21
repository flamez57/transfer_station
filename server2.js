var http = require('http');
var mysql      = require('mysql');
var connection = mysql.createConnection({
  host     : 'localhost',
  user     : 'me',
  password : 'secret',
});
//开始你的mysql连接
connection.connect();
 
var server = http.createServer(function (req, res) {
    //如果你发一个GET到http://127.0.0.1:1337/test?a=1&b=2的话
    var url_info = require('url').parse(req.url, true);
    //检查是不是给/test的request
    if(url_info.pathname === '/test'){
        //把query用url encode，这样可以用post发送
        var post_data = require('querystring').stringify(url_info.query);
        //post的option
        var post_options = {
            host: 'localhost',
            port: 1337,
            path: '/response_logic',
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Content-Length': post_data.length
            }                      
        };
        //发出post
        var request_made = http.request(post_options, function(response_received){
            var buf_list = new Array();
            response_received.on('data',function(data){
                buf_list.push(data);
            });
            response_received.on('end',function(){
                var response_body = Buffer.concat(buf_list);
                res.end(response_body);
                connection.query('insert into .........',function(err,rows,fields){
                    //处理你的结果
                });
            });
        });
        //发出post的data
        request_made.end(post_data);
    }
    //这个是用来回复上面那个post的，显示post的数据以表示成功了。你要是有别的目标，自然不需要这一段。
    else{
        req.pipe(res);
    }
});
server.listen(1337, '127.0.0.1');
//在server关闭的时候也关闭mysql连接
server.on('close',function(){
    connection.end();
});
console.log('listening on port  1337');
