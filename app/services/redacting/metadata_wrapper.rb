# module Redacting
#   class MetadataWrapper < SimpleDelegator
#     def metadata
#       {
#         status:,
#         returned_at:,
#         reviewed_at:,
#         review_status:,
#         offence_class:,
#         return_reason:,
#       }.stringify_keys
#     end

#   private

#     def return_reason
#       return_details.try(:[], "reason")
#     end
#   end
# end
