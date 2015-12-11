// First, find out the plan

$(function () {

// Set the dropdown correctly based on plan entering

// Intercept the plan changing

    // Intercept the submit
    $(".cc_form").on('submit', submitHandler);
});

// Submit handler

function submitHandler(event) {
    var $form = $(event.target);

    $form.find('input[type=submit]').prop("disabled", true);

    if(Stripe) {
        Stripe.card.createToken($form, stripeResponseHandler);
    }
    else {
        showError("Failed lo start credit card processing. Please reload the page.");
    }

    event.preventDefault();
    return false;
}

// Process the Stripe payment

// Insert the token into the data stream, but not the CC details

function stripeResponseHandler(status, response) {
    var $form = $(".cc_form");

    if(response.error) {
        console.error(response.error.message);
        showError(response.error.message);

        $form.find('input[type=submit]').prop("disabled", false);
    }
    else {
        var token = response.id;
        $form.append($('<input type="hidden" name="payment[token]" />').val(token));
        $("[data-stripe=number]").remove();
        $("[data-stripe=cvv]").remove();
        $("[data-stripe=exp-month]").remove();
        $("[data-stripe=exp-year]").remove();
        $("[data-stripe=label]").remove();

        $form.get(0).submit();
    }

    return false;
}

// Show errors, if any

