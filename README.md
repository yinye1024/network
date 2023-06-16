
# 对http和tcp的网络服务进行封装

### 添加依赖

rebar3 文件rebar.config添加依赖

    {deps, [
      {network, {git, "https://github.com/yinye1024/network", {tag, "<Latest tag>"}}}
       ]
    }

__Latest tag__ 是最新版本.

## 1 基于 mochiweb 对http服务，做进一步的封装

### 测试用例

跑用例，看console输出

>
> rebar3 eunit --module=yynw_test_http_suite
>

### 如何使用

参考测试用例

1.yynw_test_http_suite 

    测试用例，只测试了get和post。

2.yynw_test_httpd_router 

    http服务的路由，对请求进行分发。

3.yynw_test_httpd_starter 

    把 yynw_test_httpd_router 封装成 yynw_httpd_route_agent，
    然后传入给yynw_httpd_sup启动http服务。

规范使用 参考tpl/httpd

### 主要模块

1. yynw_httpd_gen

    启动http服务的管理进程。
2. yynw_httpd_route_agent

   路由代理


## 2 对tcp的服务和客户端做封装，方便使用

### 测试用例

跑用例，看console输出

>
> rebar3 eunit --module=yynw_test_tcp_suite
>

### 如何使用

参考测试用例

1.yynw_test_tcp_suite

    测试用例，test_a和test_b分别发送不同的信息给服务端，console分别输出服务端和客户端的通信信息。

2.test/tcp_svr/gw 目录下的代码，运行在网关进程，

    yynw_test_gw 用做与网关进程进行交互，实现了网关代理 yynw_tcp_gw_agent 需要调用的方法。

    yynw_test_gw_context 用做与网关进程交互的上下文，存储交互所必要的信息。

    yynw_test_gw_helper 是网关交互的帮助类。

    yynw_test_tcp_starter 会把 yynw_test_gw  封装成 yynw_tcp_gw_agent，并通过 yynw_tcp_gw_api:start(Port,GwAgent) 启动网关服务。
    

3.test/tcp_svr/role 目录下的代码，单独起进程运行，用做处理具体的业务

    网关会把客户端发送过来的信息转发到bs_yynw_test_role_mgr，进行对应的业务处理。

4.test/tcp_client 是客户端代码

    yynw_test_tcp_client 用做与客户端网关进程的交互，实现了网关代理 yynw_tcp_client_agent 需要调用的方法。
    进程启动后，bs_yynw_test_tcp_client_mgr会把 yynw_test_tcp_client 封装成 yynw_tcp_client_agent，并通过 yynw_tcp_client_api:new_client({Addr,Port,ClientAgent}) 方法启动网关进程。

规范使用 参考tpl/tcp

### 主要模块

1. yynw_tcp_client_api

    客户端api，别的模块外部不要调用。

2. yynw_tcp_gw_api

    服务端api，别的模块外部不要调用。


   
   
