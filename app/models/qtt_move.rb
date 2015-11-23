class QttMove < ActiveRecord::Base
  belongs_to :qtt
  has_one :partner_variant, class_name: "QttMove", foreign_key: :partner_id
  belongs_to :partner, class_name: "QttMove", foreign_key: :partner_id

end
