pub struct UserCollection {
    users: [&'static str; 3],
}

/// 内部に任意のユーザー配列を保持するカスタムコレクションです。
impl UserCollection {
    /// カスタムユーザーコレクションを返します。
    pub fn new() -> Self {
        Self {
            users: ["Alice", "Bob", "Carl"],
        }
    }

    /// ユーザーコレクションのイテレータを返します。
    ///
    /// メソッド名は異なっていても構いませんが、Rust の命名規則では
    /// `iter` が事実上の標準として使われています。
    pub fn iter(&self) -> UserIterator<'_> {
        UserIterator {
            index: 0,
            user_collection: self,
        }
    }

    pub fn len(&self) -> usize {
        self.users.len()
    }
}

/// UserIterator は内部の詳細を公開せずに、複雑なユーザーコレクションを
/// 順番に走査できるようにします。
pub struct UserIterator<'a> {
    index: usize,
    user_collection: &'a UserCollection,
}

impl UserIterator<'_> {
    pub fn index(&self) -> usize {
        self.index
    }
}

/// `Iterator` は Rust 標準ライブラリのイテレータを扱うための標準インターフェースです。
impl Iterator for UserIterator<'_> {
    type Item = &'static str;

    /// `next` メソッドは `Iterator` トレイトで実装が必須となる唯一のメソッドです。
    /// これにより、`fold`、`map`、`for_each` など多くの標準メソッドを利用できます。
    fn next(&mut self) -> Option<Self::Item> {
        if self.index < self.user_collection.users.len() {
            let user = Some(self.user_collection.users[self.index]);
            self.index += 1;
            return user;
        }

        None
    }
}
