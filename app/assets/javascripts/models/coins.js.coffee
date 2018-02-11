
$(document).ready ->
  $('table#coins form select').on 'change', ->
    $select = $(this)
    $form = $select.closest('form')

    $.ajax
      url: $form.attr('action') 
      type: 'post'
      data: $form.serialize()
      dataType: 'json'
      success: (data) ->
        console.log "response"
        console.log data


