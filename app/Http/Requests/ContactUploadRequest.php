<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ContactUploadRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array|string>
     */
    public function rules(): array
    {
        return [
            'csv_file' => 'required|file|mimes:csv,txt|max:51200', // 50MB max for large files
        ];
    }

    /**
     * Get custom messages for validator errors.
     *
     * @return array
     */
    public function messages(): array
    {
        return [
            'csv_file.required' => 'The CSV file is required.',
            'csv_file.file' => 'The uploaded file must be a valid file.',
            'csv_file.mimes' => 'The file must be a CSV or TXT file.',
            'csv_file.max' => 'The file may not be larger than 50MB.',
        ];
    }
}
