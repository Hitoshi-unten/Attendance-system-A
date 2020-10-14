class User < ApplicationRecord
  # Userクラスが定義されていること、UserクラスはApplicationRecordクラスを継承していることがわかる。この継承の働きによりActive Recordのメソッドが使えるということは覚えておく。
  # ファイルにはこれしか書かれていないが、このUserクラスがApplicationRecordクラスを継承していることに注目。これによって基本的なデータベースCRUD (Create、Read、Update、Destroy) 操作やデータのバリデーション（検証: validation）のほか、洗練された検索機能や複数のモデルを互いに関連付ける機能(リレーションシップ) など、きわめて多くの機能をRailsモデルに無償で提供している。
  # AttendanceモデルからみたUserモデルとの関連性は１対１だがUserモデルからみた場合、その関係は１（user）対多（Attendance）となる。
  # Attendanceモデルファイルに記述されていたbelong_toとは違った記述が必要になる。has many〜と記述する。また、多数所持するため、複数形（attendances）となっている点もポイント。
  # 関連性としては、userが親で、attendancesが子という関係になる。
  has_many :attendances, dependent: :destroy
  # UserモデルがAttendanceモデルに対して、１対多の関連性を示すコード。
  # dependent: :destroy ユーザーが削除された場合、関連する勤怠データも同時に自動で削除される。この設定の追加で、ユーザーを削除したのに勤怠データがデータベースに取り残されてしまう状態を防げる。
  attr_accessor :remember_token
  # 「remember_token」という仮想の属性を作成します。
  before_save { self.email = email.downcase }
  validates :name, presence: true, length: { maximum: 50 } #名前（name）カラムに存在性の検証（空の投稿を認めない） すべての記事に名前が存在し、その長さが50字以下であることが保証される。そうでない場合には記事はデータベースに保存されない。Railsには豊富なバリデーション機能があり、存在確認、カラムでの重複確認、フォーマット確認、関連付けられたオブジェクトがあるかどうかの確認などが行える。バリデーション機能が追加されたので、バリデーションをパスしない@userに対して@user.saveを実行するとfalseが返されるようになっている。

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 100 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: true
  validates :affiliation, length: { in: 2..50 }, allow_blank: true
  validates :basic_work_time, presence: true
  validates :designated_work_start_time, presence: true
  validates :designated_work_end_time, presence: true
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  # 渡された文字列のハッシュ値を返します。
  def User.digest(string)
    cost = 
      if ActiveModel::SecurePassword.min_cost
        BCrypt::Engine::MIN_COST
      else
        BCrypt::Engine.cost
      end
    BCrypt::Password.create(string, cost: cost)
  end

  # ランダムなトークンを返します。
  def User.new_token
    SecureRandom.urlsafe_base64
  end

  # 永続セッションのためハッシュ化したトークンをデータベースに記憶します。
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # トークンがダイジェストと一致すればtrueを返します。
  def authenticated?(remember_token)
    # ダイジェストが存在しない場合はfalseを返して終了します。
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  # ユーザーのログイン情報を破棄します。
  def forget
    update_attribute(:remember_digest, nil)
  end
  
  def self.search(search) #ここでのself.はUser.を意味する
    if search
      User.where(['name LIKE ?', "%#{search}%"]) #検索とnameの部分一致を表示。User.は省略
    else
      all #全て表示。User.は省略
    end
  end
  
  def self.in_working_users
    in_working_users = Attendance.where(worked_on: Date.today,finished_at: nil).where.not(started_at: nil).pluck(:user_id).uniq
    User.where(id: in_working_users)
  end
end