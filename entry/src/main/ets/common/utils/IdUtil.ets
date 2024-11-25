export default class IdUtil {

  public static count: number = 0

  public static generateId() {
    return (Date.parse(new Date().toString()) + IdUtil.count++).toString()
  }
}