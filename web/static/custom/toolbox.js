function show_whois_lookup_modal(){
	$('#modal_title').html('WHOIS Lookup');
	$('#modal-content').empty();
	$('#modal-content').append(`
		<div class="mb-3">
			<label for="whois_domain_name" class="form-label">Domain Name/IP Address</label>
			<input class="form-control" type="text" id="whois_domain_name" required="" placeholder="yourdomain.com">
		</div>
		<div class="mb-3 text-center">
			<button class="btn btn-primary float-end" type="submit" id="search_whois_toolbox_btn" onclick="toolbox_lookup_whois()">Search Whois</button>
		</div>
	`);
	$('#modal_dialog').modal('show');
}

function toolbox_lookup_whois(){
	var domain = document.getElementById("whois_domain_name").value;
	if (domain) {
		get_domain_whois(domain, show_add_target_btn=true);
	}
	else{
		swal.fire("Error!", 'Please enter the domain/IP Address!', "warning", {
			button: "Okay",
		});
	}
}



function toolbox_cve_detail(){
	$('#modal_title').html('CVE Details Lookup');
	$('#modal-content').empty();
	$('#modal-content').append(`
		<div class="mb-1">
			<label for="cve_id" class="form-label">CVE ID</label>
			<input class="form-control" type="text" id="cve_id" required="" placeholder="CVE-XXXX-XXXX">
		</div>
		<div class="mt-3 mb-3 text-center">
			<button class="btn btn-primary float-end" type="submit" id="cve_detail_submit_btn">Lookup CVE</button>
		</div>
	`);
	$('#modal_dialog').modal('show');
}



$(document).on('click', '#cve_detail_submit_btn', function(){
	var cve_id = document.getElementById("cve_id").value;
	if (cve_id) {
		get_and_render_cve_details(cve_id);
	}
	else{
		swal.fire("Error!", 'Please enter CVE ID!', "warning", {
			button: "Okay",
		});
	}
});


