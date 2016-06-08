var APTCModule = ( function( window, undefined ) {

  // APTC Calculations
  function calculateAvailableAPTC(caller_input) {
    var person_id = $("#person_person_id").val();
    var family_id = $("#person_family_id").val();

    // if (isNaN( parseFloat($('input#max_aptc').val()) )) {
    //   alert("Max APTC is NaN: " + $('input#max_aptc').val());

    // }
    // Household / Eligibility Stuff
    //alert($('input#max_aptc').val());
    var max_aptc = parseFloat($('input#max_aptc').val());
    //alert(max_aptc);
    var csr_percentage = $("#csr_percentage").val();
    
    // Enrollment Level Stuff
    // Create an array of hash that contains [hbx_id, changed_applied_aptc_value] for all the enrollments
    var aptc_applied_input_elements = $('#enrollmentsDiv').find("input[name^='aptc_applied_']");
    var applied_aptcs_array = [];
    for (var i=0; i<aptc_applied_input_elements.length; i++) {
      var hbx_id  = aptc_applied_input_elements[i].id;
      var aptc_applied = aptc_applied_input_elements[i].value;
      var one_enrollment_hash = {"hbx_id":hbx_id, "aptc_applied":aptc_applied};
      applied_aptcs_array.push(one_enrollment_hash);
    }
    
    $('#loading-'+caller_input+'-aptc').html('<img src="/assets/loading_aptc.gif" height="30" width="30">  &nbsp;&nbsp; <b>Recalculating...</b>');

    //if (!isNaN(csr_percentage) && !isNaN(max_aptc)){
      $.ajax({
        type: "GET",
        //data:{person_id: person_id, family_id: family_id, max_aptc: max_aptc, csr_percentage: csr_percentage, applied_aptcs_array: applied_aptcs_array, member_ids: member_ids},
        data:{person_id: person_id, family_id: family_id, max_aptc: max_aptc, csr_percentage: csr_percentage, applied_aptcs_array: applied_aptcs_array},
        url: "/hbx_admin/calculate_aptc_csr",
        success: function (d) {
            //$('#loading').html("");
        }
      });
    //}
    // else {
    //   // Check if max_aptc or csr_percentage is NaN and show a validation error acccordingly.
    //   if (isNaN(max_aptc))
    //     alert("Max APTC must be a positive number");
    // }
  }

  // RESET
  function resetFormData()  { 
    var person_id = $("#person_person_id").val();
    var family_id = $("#person_family_id").val();
    $('#reset-aptc').html('<img src="/assets/loading_aptc.gif" height="30" width="30">  &nbsp;&nbsp; <b>Resetting Data...</b>');
    $.ajax({
      type: "GET",
      data:{person_id: person_id, family_id: family_id},
      url: "/hbx_admin/edit_aptc_csr",
      success: function (d) {
              $('#loading').html("");
      }
    });
  }

  // Compute Applied APTC when the slider ratio changes.
  function computeAppliedAPTC(hbx_id_for_slider, aptc_ratio, max_aptc) {
    // Find All Enrollments
    var aptc_applied_input_elements = $('#enrollmentsDiv').find("input[name^='aptc_applied_']");
    //var applied_aptcs_array = [];
    for (var i=0; i<aptc_applied_input_elements.length; i++) {
      var hbx_id  = aptc_applied_input_elements[i].id;
      var aptc_applied = aptc_applied_input_elements[i].value;

      if (hbx_id_for_slider == hbx_id.replace('aptc_applied_','')){
        // update applied_aptc_ratio percent when slider changes
        $( "#aptc_applied_pct_"+hbx_id_for_slider ).val((aptc_ratio*100).toFixed(0)+'%');   
        // update applied_aptc text value to match the percent.
        $("#"+hbx_id).val((aptc_ratio * max_aptc).toFixed(2));
      }
    }

  }

  function computePercentageAndSliderRatio(hbx_id, applied_aptc_amount, max_aptc) {
    // update applied_aptc_ratio on the slider bar
    $( "#applied_pct_"+hbx_id).val(applied_aptc_amount/max_aptc);
    // update applied_aptc_ratio percent when aptc_applied_amount on the textbox changes.
    $( "#aptc_applied_pct_"+hbx_id ).val((applied_aptc_amount/max_aptc*100).toFixed(0)+'%');
          
  }

  // explicitly return these public methods when this object is instantiated
  return {
    calculateAvailableAPTC : calculateAvailableAPTC,
    computeAppliedAPTC : computeAppliedAPTC,
    computePercentageAndSliderRatio : computePercentageAndSliderRatio,
    resetFormData : resetFormData
  };

} )( window );

