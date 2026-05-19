function load_nuclei_template(pattern_name){
  Swal.fire({
		title: `Fetching Nuclei template ${pattern_name}...`,
	});
	swal.showLoading();

  $.getJSON(`/api/getFileContents?nuclei_template&name=${pattern_name}&format=json`, function(response) {
    swal.close();
    if (response.status) {
      $('#modal_title').empty();
      $('#modal-content').empty();
      $("#modal-footer").empty();

      $('#modal_title').html(`Nuclei Template: ` + htmlEncode(pattern_name));

      $('#modal-content').append(`<pre>${htmlEncode(response['content'])}</pre>`);
      $('#modal_dialog').modal('show');
    }
    else{
      swal.fire("Error!", response.message, "error", {
        button: "Okay",
      });
    }

  }).fail(function(){
    swal.fire("Error!", 'Error loading Nuclei Template!', "error", {
      button: "Okay",
    });
  });
}


// get nuclei config
$.getJSON(`/api/getFileContents?nuclei_config&format=json`, function(data) {
  $("#nuclei_config_text_area").attr("rows", 17);
  $("textarea#nuclei_config_text_area").html(data['content']);
}).fail(function(){
  $("#nuclei_config_text_area").removeAttr("readonly");
  $("textarea#nuclei_config_text_area").html(`# Your nuclei configuration here.`);
  $("#nuclei-config-form").append('<input type="submit" class="btn btn-primary mt-2 float-end" value="Save Changes" id="nuclei-config-submit">');
});

$("#nuclei_config_text_area").dblclick(function() {
  if (!document.getElementById('nuclei-config-submit')) {
    $("#nuclei_config_text_area").removeAttr("readonly");
    $("#nuclei-config-form").append('<input type="submit" class="btn btn-primary mt-2 float-end" value="Save Changes" id="nuclei-config-submit">');
  }
});


// get Naabu config
$.getJSON(`/api/getFileContents?naabu_config&format=json`, function(data) {
  $("#naabu_config_text_area").attr("rows", 14);
  $("textarea#naabu_config_text_area").html(htmlEncode(data['content']));
}).fail(function(){
  $("#naabu_config_text_area").removeAttr("readonly");
  $("textarea#naabu_config_text_area").html(`# Your Naabu configuration here.`);
  $("#naabu-config-form").append('<input type="submit" class="btn btn-primary mt-2 float-end" value="Save Changes" id="naabu-config-submit">');
});

$("#naabu_config_text_area").dblclick(function() {
  if (!document.getElementById('naabu-config-submit')) {
    $("#naabu_config_text_area").removeAttr("readonly");
    $("#naabu-config-form").append('<input type="submit" class="btn btn-primary mt-2 float-end" value="Save Changes" id="naabu-config-submit">');
  }
});
