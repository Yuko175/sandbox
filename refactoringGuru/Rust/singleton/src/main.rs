use std::sync::OnceLock;

#[derive(Debug)]
pub struct AppConfig {
    pub app_name: String,
    pub version: String,
}

impl AppConfig {
    // シングルトンインスタンスを取得する関数
    pub fn global(app_name: &str) -> &'static AppConfig {
        static INSTANCE: OnceLock<AppConfig> = OnceLock::new();
        INSTANCE.get_or_init(|| {
            // 初回アクセス時にのみ実行される初期化処理
            AppConfig {
                app_name: String::from(app_name),
                version: String::from("1.0.0"),
            }
        })
    }
}

fn main() {
    // どこから呼び出しても同じ実体を参照する
    let config1 = AppConfig::global("MyRustApp1");
    let config2 = AppConfig::global("MyRustApp2");

    println!("App Name1: {}", config1.app_name);
    println!("App Name2: {}", config2.app_name);
}
