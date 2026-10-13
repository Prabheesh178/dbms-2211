/**
 * Main JavaScript utilities for Sports Club DBMS.
 */

document.addEventListener('DOMContentLoaded', function () {
    // Auto-dismiss alerts after 6 seconds
    const alerts = document.querySelectorAll('.alert-dismissible');
    alerts.forEach(function (alert) {
        setTimeout(function () {
            const bsAlert = new bootstrap.Alert(alert);
            bsAlert.close();
        }, 6000);
    });

    // Facility conflict checker on facility_booking.html
    const conflictForm = document.getElementById('facilityConflictForm');
    const conflictResult = document.getElementById('conflictResult');

    if (conflictForm && conflictResult) {
        conflictForm.addEventListener('submit', function (e) {
            e.preventDefault();
            const formData = new FormData(conflictForm);
            conflictResult.innerHTML = '<div class="spinner-border spinner-border-sm text-primary" role="status"></div> Checking schedule...';
            conflictResult.className = 'alert alert-info py-2 px-3 mt-3';
            conflictResult.style.display = 'block';

            fetch('/facilities/check_conflict', {
                method: 'POST',
                body: formData
            })
            .then(res => res.json())
            .then(data => {
                if (data.conflict) {
                    conflictResult.className = 'alert alert-danger py-2 px-3 mt-3';
                    conflictResult.innerHTML = '<i class="bi bi-exclamation-triangle-fill me-2"></i><strong>Conflict:</strong> ' + data.message;
                } else {
                    conflictResult.className = 'alert alert-success py-2 px-3 mt-3';
                    conflictResult.innerHTML = '<i class="bi bi-check-circle-fill me-2"></i>' + data.message;
                }
            })
            .catch(err => {
                conflictResult.className = 'alert alert-warning py-2 px-3 mt-3';
                conflictResult.innerHTML = '<i class="bi bi-wifi-off me-2"></i>Error checking schedule: ' + err.message;
            });
        });
    }
});
