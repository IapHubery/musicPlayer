
import http from '@ohos.net.http';
import { JSON } from '@kit.ArkTS';

export default async function getHttpData(url: string): Promise<string> {

  let httpRequest = http.createHttp();
  let response = httpRequest.request(
    // 填写HTTP请求的URL地址，可以带参数也可以不带参数。URL地址需要开发者自定义。请求的参数可以在extraData中指定
    url,
    {
      method: http.RequestMethod.GET, // 可选，默认为http.RequestMethod.GET
      // 开发者根据自身业务需要添加header字段
      header: {
        'Content-Type': 'application/json'
      },
      expectDataType: http.HttpDataType.STRING, // 可选，指定返回数据的类型
    }
  );
  let res: string | undefined = ''
  // 使用await和async，等待请求完成处理数据后返回
  await response.then((response) => {
    if (response.responseCode == 200) {
      // 处理返回结果
      const data = response.result + "";
      res = JSON.parse(data)?.toString()
    } else {
      // todo 请求失败，进行失败逻辑处理
    }
  })
  return res;
}