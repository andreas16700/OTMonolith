import Vapor
import OTModelSyncer
import MockShopifyClient
import MockPowersoftClient
import ShopifyKit
import PowersoftKit


struct ClientsInfo: Codable{
	let psURL: URL
	let shURL: URL
}
struct SyncModelInput: Codable{
	let clientsInfo: ClientsInfo
	let modelCode: String
	let model: [PSItem]?
	let psStocks: [PSListStockStoresItem]?
	let product: SHProduct?
	let shInv: [InventoryLevel]?
}
extension SingleModelSync: Content{}
extension HTTPStatus: Error{}
enum SyncErrors: Error{
	case syncFailed
}
func routes(_ app: Application) throws {
    app.get { req async in
		
        return "It works!"
    }
	app.post("syncModel"){ req async throws -> SingleModelSync in
		guard let input = try decodeToType(req.body.data, to: SyncModelInput.self) else {throw HTTPStatus.badRequest}
		let syncer = input.makeSyncer()
		guard let s = await syncer.sync() else {
			throw SyncErrors.syncFailed
		}
		return s
	}
    app.get("hello") { req async -> String in
        "Hello, world!"
    }
}
let decoder = JSONDecoder()
func decodeToType<T: Decodable>(_ b: ByteBuffer?, to type: T.Type)throws ->T?{
	guard let buf = b else {try reportError(ServerErrors.emptyBody); return nil}
	return try decoder.decode(T.self, from: buf)
}
func reportError(_ e: Error? = nil, _ msg: String? = nil)throws{
	if let msg{
		print(msg)
	}
	if let e{
		print("\(e)")
	}
	throw e ?? ServerErrors.other(msg ?? "unknown error occured")
}
enum ServerErrors:Error{
	case emptyBody
	case nonUTF8Body
	case nonDecodableBody
	case other(String)
}
extension SyncModelInput{
	func makeSyncer()->SingleModelSyncer{
		var psData: ([PSItem],[PSListStockStoresItem])? = nil
		var shData: (SHProduct, [InventoryLevel])? = nil
		if let model, let psStocks{
			psData = (model,psStocks)
		}
		if let product, let shInv{
			shData = (product, shInv)
		}
		let ps = MockPsClient(baseURL: clientsInfo.psURL)
		let sh = MockShClient(baseURL: clientsInfo.shURL)
		return .init(modelCode: modelCode, ps: ps, sh: sh, psDataToUse: psData, shDataToUse: shData)
	}
}
struct SyncModelResult{
	let input: SyncModelInput
	let dictOutput: [String: Any]
	let succ: [String: Any]?
	let nanos: UInt64
	
//	func save()throws{
//		let fm = FileManager.default
//		let resultDesc = succ == nil ? "_fail" : "_succ"
//		let baseFileName = input.modelCode + resultDesc
//		let basePath = URL(fileURLWithPath: fm.currentDirectoryPath).appendingPathComponent(baseFileName)
//		try fm.createDirectory(at: basePath, withIntermediateDirectories: true)
//		let inpURL = basePath.appending(path: "input.json")
//		try input.write(fileURL: inpURL)
//		let dicURL = basePath.appending(path: "dicOutput.json")
//		try JSONSerialization.writeObject(object: dictOutput, to: dicURL)
//		if let succ{
//			let succURL = basePath.appending(path: "success.json")
//			try JSONSerialization.writeObject(object: succ, to: succURL)
//		}
//	}
}
func measureInNanos<T>(_ work: ()async throws->T)async rethrows -> (UInt64, T){
	let s: DispatchTime
	let e: DispatchTime
	let r: T
	s = .now()
	r = try await work()
	e = .now()
	let duration = e.uptimeNanoseconds - s.uptimeNanoseconds
	return (duration, r)
}
